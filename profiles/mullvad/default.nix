{ config, lib, ... }:

{
  sops.secrets.mullvadAccount = {
    sopsFile = ./secrets.yaml;
    path = "/etc/mullvad-vpn/account-history.json";
  };

  environment.persistence.state.files = [
    # Contains the device-specific rotated Wireguard private key. If this is
    # not persistent, new devices from the associated Mullvad account have to
    # be removed each time the device is restarted.
    "/etc/mullvad-vpn/device.json"
  ];

  services.mullvad-vpn.enable = true;

  systemd.services.mullvad-daemon = {
    serviceConfig.LoadCredential = [ "mullvadAccount:${config.sops.secrets.mullvadAccount.path}" ];
    path = [ config.services.mullvad-vpn.package ];

    postStart = ''
      while ! mullvad status > /dev/null; do
        echo "Waiting for mullvad-daemon to initialize..."
        sleep 1
      done
      echo "mullvad-daemon initialized."

      account="$(systemd-creds cat 'mullvadAccount')"
      if [ "$(mullvad account get 2>&1 | head -n 1 | cut -d ':' -f 2 | tr -d ' ')" != "$account" ]; then
        echo "Logging into Mullvad..."
        mullvad account login "$account"
      fi

      if [ $? -ne 0 ]; then
        echo "Could not log into Mullvad! Exiting..."
        exit 1
      fi

      # If this is the first time connecting after logging in, it will most likely
      # fail, so we need to retry if necessary.
      while
        echo "Connecting to Mullvad..."
        mullvad connect
        sleep 1
        [ "$(mullvad status | cut -d ':' -f 1)" == 'Blocked' ]
      do true; done
    '';
  };

  networking.nftables = lib.mkIf config.services.tailscale.enable {
    enable = true;

    # Mullvad and Tailscale will fight to the death over routing rules (and
    # Mullvad will win) unless we set exceptions for Tailscale:
    # https://github.com/tailscale/tailscale/issues/925#issuecomment-1616354736.
    tables."mullvad-tailscale" = {
      family = "inet";
      content = ''
        chain prerouting {
          type filter hook prerouting priority -100; policy accept;
          ip saddr 100.64.0.0/10 ct mark set 0x00000f41 meta mark set 0x6d6f6c65;
        }

        chain outgoing {
          type route hook output priority -100; policy accept;
          meta mark 0x80000 ct mark set 0x00000f41 meta mark set 0x6d6f6c65;
          ip daddr 100.64.0.0/10 ct mark set 0x00000f41 meta mark set 0x6d6f6c65;
        }
      '';
    };
  };
}
