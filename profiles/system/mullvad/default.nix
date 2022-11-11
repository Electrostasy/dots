{ config, pkgs, ... }:

# TODO: Consider adding declarative systemd-network configuration for Mullvad

{
  services.mullvad-vpn.enable = true;
  environment.systemPackages = [ pkgs.mullvad ];

  sops.secrets.mullvadAccount.sopsFile = ./secrets.yaml;
  environment.etc."mullvad-vpn/account-history.json" = {
    source = config.sops.secrets.mullvadAccount.path;
  };
}

