{ config, pkgs, lib, ... }:

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
      while ! mullvad status &> /dev/null; do
        sleep 1
      done

      account="$(systemd-creds cat 'mullvadAccount')"
      if [ "$(mullvad account get 2>&1 | head -n 1 | cut -d ':' -f 2 | tr -d ' ')" != "$account" ]; then
        mullvad account login "$account"
      fi

      # If this is the first time connecting after logging in, it will most likely
      # fail, so we need to retry if necessary.
      while
        echo "Connecting to Mullvad..."
        mullvad connect
        sleep 1
        [ "$(mullvad status | cut -d ':' -f 1)" == 'Blocked' ]
      do true; done

      # This is important, otherwise NFS transfers over Tailscale are very slow
      # (between 2-3 times slower) because they have to go through the VPN.
      mullvad lan set allow
    '';
  };

  # Mullvad does not let any incoming LAN connections on subnets other than the
  # ones they have whitelisted (for IPv4 at the time of writing: 10.0.0.0/8,
  # 172.16.0.0/12, 192.168.0.0/16, 169.254.0.0/16), so, in practice, incoming
  # Tailscale connections cannot be accepted with just firewall rules:
  # https://github.com/mullvad/mullvadvpn-app/issues/6086
  # https://github.com/mullvad/mullvadvpn-app/blob/045a5c33f140945072e42553939adcf7bace52c1/talpid-types/src/net/mod.rs#L24
  # As a workaround, for outgoing connections, the outgoing nftables chain is
  # enough. However, for incoming connections, we require BOTH the prerouting
  # nftables chain as well as the NetworkManager dispatcher script to add the
  # route. Without these, a host running Mullvad, even with LAN sharing
  # enabled, will completely drop all ICMP and other incoming requests over
  # Tailscale.
  networking = lib.mkIf config.services.tailscale.enable {
    nftables = {
      enable = true;

      tables."ts-mullvad" = {
        family = "inet";

        # Marks traffic with a connection tracking mark (0x00000f41) to get
        # through the firewall and a meta mark (0x6d6f6c65) to route the traffic
        # outside the tunnel:
        # https://mullvad.net/en/help/split-tunneling-with-linux-advanced#allow-incoming
        content = ''
          chain prerouting {
            type filter hook prerouting priority -100; policy accept;
            ip saddr 100.64.0.0/10 ct mark set 0x00000f41 meta mark set 0x6d6f6c65;
          }

          chain outgoing {
            type route hook output priority -100; policy accept;
            ip daddr 100.64.0.0/10 ct mark set 0x00000f41 meta mark set 0x6d6f6c65;
          }
        '';
      };
    };

    networkmanager = {
      enable = true;

      dispatcherScripts = [
        {
          # https://github.com/mullvad/mullvadvpn-app/issues/6833#issuecomment-2387277203
          source = pkgs.writeShellScript "add-tailscale-route.sh" ''
            if [ "$1" == "tailscale0" ]; then
              if [ "$2" == "up" ]; then
                ip route add 100.64.0.0/10 dev tailscale0 table main
              elif [ "$2" == "down" ]; then
                ip route del 100.64.0.0/10 dev tailscale0 table main
              fi
            fi
          '';
          type = "basic";
        }
      ];
    };
  };
}
