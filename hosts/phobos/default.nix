{ config, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/profiles/minimal.nix"
    ../../profiles/shell.nix
    ../../profiles/ssh.nix
    ../../profiles/tailscale.nix
    ../../profiles/users/electro
    ../../profiles/zramswap.nix
    ./fail2ban.nix
    ./fileserver.nix
    ./headscale.nix
    ./hostapd.nix
    ./murmur.nix
    ./prometheus.nix
    ./prosody.nix
  ];

  nixpkgs.hostPlatform.system = "aarch64-linux";

  image.modules.default.imports = [
    ../../profiles/image/expand-root.nix
    ../../profiles/image/generic-efi.nix
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

  services = {
    prometheus.exporters.node.enable = true;

    nginx = {
      enable = true;

      recommendedTlsSettings = true;
    };

    journald.remote = {
      enable = true;

      listen = "http";
    };
  };

  fileSystems = {
    "/var/log/nginx" = {
      device = "/dev/disk/by-label/pidata";
      fsType = "btrfs";
      options = [
        "subvol=nginx"
        "noatime"
        "X-mount.group=${config.users.groups.nginx.name}"
      ];
    };

    "/var/log/journal" = {
      device = "/dev/disk/by-label/pidata";
      fsType = "btrfs";
      options = [
        "subvol=journal"
        "noatime"
        "X-mount.group=${config.users.groups.systemd-journal.name}"
      ];
    };
  };

  networking.firewall = {
    enable = true;

    allowedTCPPorts = [
      80
      443
    ];

    interfaces.${config.services.tailscale.interfaceName} = {
      allowedTCPPorts = [
        config.services.prometheus.exporters.node.port
        config.services.journald.remote.port
      ];
    };
  };

  system.stateVersion = "25.05";
}
