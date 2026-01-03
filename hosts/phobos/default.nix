{ config, ... }:

{
  imports = [
    ../../profiles/minimal.nix
    ../../profiles/shell.nix
    ../../profiles/ssh.nix
    ../../profiles/tailscale.nix
    ../../users/electro
    ./acme.nix
    ./dendrite.nix
    ./discord-transcriber.nix
    ./fileserver.nix
    ./headscale.nix
    ./hostapd.nix
    ./prometheus.nix
  ];

  nixpkgs.hostPlatform.system = "aarch64-linux";

  image.modules.default.imports = [
    ../../profiles/image/expand-root.nix
    ../../profiles/image/generic-efi.nix
    ../../profiles/image/interactive.nix
    ../../profiles/image/platform/raspberrypi-4-b.nix
  ];

  hardware.deviceTree.name = "broadcom/bcm2711-rpi-4-b.dtb";

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = false;
    };

    kernelParams = [ "8250.nr_uarts=1" ];

    initrd = {
      systemd.root = "gpt-auto";
      supportedFilesystems.ext4 = true;
    };
  };

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 15d";
    };

    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };
  };

  zramSwap.enable = true;

  networking.firewall.interfaces.${config.services.tailscale.interfaceName}.allowedTCPPorts = [ config.services.prometheus.exporters.node.port ];
  services.prometheus.exporters.node.enable = true;

  services.journald.storage = "volatile";

  system.stateVersion = "25.05";
}
