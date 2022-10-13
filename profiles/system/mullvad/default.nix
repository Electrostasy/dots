{ config, pkgs, lib, persistMount, ... }:

# TODO: Consider adding declarative systemd-network configuration for Mullvad

{
  sops.secrets.mullvadAccount.sopsFile = ./secrets.yaml;

  services.mullvad-vpn.enable = true;

  environment = {
    systemPackages = [ pkgs.mullvad ];
    etc."mullvad-vpn/account-history.json".source = config.sops.secrets.mullvadAccount.path;
  } // lib.optionalAttrs (persistMount != "") {
    persistence.${persistMount}.files = [
      # Contains the device-specific rotated Wireguard private key. If this isn't
      # stateful, I have to keep removing newly created devices from the Mullvad
      # account each time I reboot
      "/etc/mullvad-vpn/device.json"

      "/var/cache/mullvad-vpn/relays.json"
    ];
  };
}

