{ config, pkgs, flake, ... }:

{
  imports = [
    ../../profiles/minimal.nix
    ../../profiles/shell.nix
    ../../profiles/ssh
    ../../profiles/tailscale.nix
    ./nfs.nix
    ./samba.nix
  ];

  nixpkgs = {
    hostPlatform.system = "aarch64-linux";
    overlays = [ flake.overlays.emc2305-patched ];
  };

  image.modules.default.imports = [
    ../../profiles/image/expand-root.nix
    ../../profiles/image/generic-efi.nix
    ../../profiles/image/interactive.nix
    ../../profiles/image/platform/raspberrypi-cm4.nix
  ];

  sops = {
    defaultSopsFile = ./secrets.yaml;

    secrets = {
      electroPassword.neededForUsers = true;
      sukcenoPassword.neededForUsers = true;
      electroIdentity = {
        mode = "0400";
        owner = config.users.users.electro.name;
      };
    };
  };

  hardware.deviceTree = {
    name = "broadcom/bcm2711-rpi-cm4-io.dtb";

    overlays = [
      {
        name = "enable-xhci-overlay";
        dtsFile = ./enable-xhci.dtso;
      }
      {
        name = "fan-control-overlay";
        dtsFile = ./fan-control.dtso;
      }
    ];
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = false;
    };

    kernelPackages = pkgs.linuxPackages_latest; # >=6.16 for emc2305 OF support.
    kernelParams = [ "8250.nr_uarts=1" ];

    extraModulePackages = [ config.boot.kernelPackages.emc2305 ];

    initrd = {
      systemd = {
        root = "gpt-auto";
        tpm2.enable = false;
      };

      supportedFilesystems.ext4 = true;

      includeDefaultModules = false;
      availableKernelModules = [ "mmc_block" ];
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

  # Formatted from 5 disks using:
  # $ mkfs.btrfs -d raid6 -m raid1c3 /dev/disk/by-id/ata-ST18000NM003D-3DL103_* -L array
  # $ btrfs property set /mnt/array compression zstd:3
  fileSystems."/mnt/array" = {
    device = "/dev/disk/by-label/array";
    fsType = "btrfs";
    options = [ "noatime" ];
  };

  zramSwap.enable = true;

  networking.firewall.interfaces.${config.services.tailscale.interfaceName}.allowedTCPPorts = [ config.services.prometheus.exporters.node.port ];

  services = {
    prometheus.exporters.node.enable = true;

    journald.storage = "volatile";

    btrfs.autoScrub = {
      enable = true;

      interval = "monthly";
      fileSystems = [ "/mnt/array" ];
    };

    hddfancontrol = {
      enable = true;

      settings.harddrives = {
        disks = [
          "/dev/disk/by-path/platform-fd500000.pcie-pci-0000:01:00.0-ata-1.0"
          "/dev/disk/by-path/platform-fd500000.pcie-pci-0000:01:00.0-ata-2.0"
          "/dev/disk/by-path/platform-fd500000.pcie-pci-0000:01:00.0-ata-3.0"
          "/dev/disk/by-path/platform-fd500000.pcie-pci-0000:01:00.0-ata-4.0"
          "/dev/disk/by-path/platform-fd500000.pcie-pci-0000:01:00.0-ata-5.0"
        ];

        pwmPaths = [
          "/sys/class/hwmon/hwmon2/pwm2:100:0"
          "/sys/class/hwmon/hwmon2/pwm3:100:0"
        ];

        extraArgs = [ "--interval=1min" ];
      };
    };
  };

  users.users = {
    electro = {
      isNormalUser = true;
      uid = 1000;

      # Change password using:
      # $ systemd-ask-password | mkpasswd -m SHA-512 -s
      hashedPasswordFile = config.sops.secrets.electroPassword.path;

      extraGroups = [ "wheel" ];

      openssh.authorizedKeys.keyFiles = [
        ../mercury/id_ed25519.pub
        ../terra/id_ed25519.pub
        ../venus/id_ed25519.pub
      ];
    };

    sukceno = {
      isNormalUser = true;
      uid = 1001;

      hashedPasswordFile = config.sops.secrets.sukcenoPassword.path;
    };
  };

  system.stateVersion = "24.05";
}
