{ config, ... }:

{
  sops.secrets.mullvadAccount.sopsFile = ./secrets.yaml;
  environment.etc."mullvad-vpn/account-history.json".source = config.sops.secrets.mullvadAccount.path;

  services.mullvad-vpn.enable = true;

  networking.nftables = {
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
