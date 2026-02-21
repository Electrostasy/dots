{ config, ... }:

{
  imports = [
    ../../profiles/minimal.nix
    ../../profiles/shell.nix
    ../../profiles/ssh.nix
    ../../profiles/tailscale.nix
    ../../profiles/zramswap.nix
    ../../users/electro
    ./dendrite.nix
    ./discord-transcriber.nix
    ./fileserver.nix
    ./headscale.nix
    ./hostapd.nix
    ./prometheus.nix
    ./prosody.nix
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

  networking.firewall.interfaces.${config.services.tailscale.interfaceName}.allowedTCPPorts = [
    config.services.prometheus.exporters.node.port
    config.services.journald.remote.port
  ];

  services.prometheus.exporters.node.enable = true;

  fileSystems."/var/log/journal" = {
    device = "/dev/disk/by-label/pidata";
    fsType = "btrfs";
    options = [
      "subvol=journal"
      "noatime"
      "X-mount.group=${config.users.groups.systemd-journal.name}"
    ];
  };

  services.journald.remote = {
    enable = true;

    listen = "http";
  };

  system.stateVersion = "25.05";
}
