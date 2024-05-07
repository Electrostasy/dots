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

  networking.nftables = lib.mkIf config.services.tailscale.enable {
    enable = true;

    # Mullvad and Tailscale will fight to the death over routing rules (and
    # Mullvad will win) unless we set exceptions for Tailscale. Issue link:
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
