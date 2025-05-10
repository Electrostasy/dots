{ config, pkgs, lib, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/profiles/minimal.nix"
    ../../profiles/shell
    ../../profiles/ssh
    ../../profiles/tailscale.nix
    ./nfs.nix
  ];

  nixpkgs.hostPlatform.system = "aarch64-linux";

  image.modules = lib.mkForce { raw = ./image.nix; };

  sops = {
    defaultSopsFile = ./secrets.yaml;

    secrets = {
      electroPassword.neededForUsers = true;
      electroIdentity = {
        mode = "0400";
        owner = config.users.users.electro.name;
      };
    };
  };

  # NOTE: If the device tree changes, it needs to be re-added into the /boot
  # directory where the firmware lives:
  # https://forums.raspberrypi.com/viewtopic.php?t=370304#p2227480
  hardware.deviceTree = {
    name = "broadcom/bcm2711-rpi-cm4-io.dtb";

    overlays = [
      {
        name = "enable-xhci-overlay";
        dtsFile = ./enable-xhci.dts;
      }
      {
        name = "fan-control-overlay";
        dtsFile = ./fan-control.dts;
      }
    ];
  };

  boot = {
    loader.generic-extlinux-compatible.enable = true;

    kernelPackages = pkgs.linuxPackages_latest;

    # Use emc230x instead of the in-kernel emc2305 driver.
    blacklistedKernelModules = [ "emc2305" ];
    extraModulePackages = [ (pkgs.emc230x.override { linuxPackages = config.boot.kernelPackages; }) ];

    kernelParams = [
      "8250.nr_uarts=1"
      "console=ttyS0,115200"
    ];

    initrd = {
      includeDefaultModules = false;
      availableKernelModules = [
        "mmc_block" # required to boot from eMMC.
        "usb-storage"
        "xhci-hcd"
      ];

      systemd = {
        emergencyAccess = true;
        tpm2.enable = false;
      };
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

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-label/BOOT";
      fsType = "vfat";
      options = [ "umask=0077" ];
    };

    # Formatted from 5 disks using:
    # $ mkfs.btrfs -d raid6 -m raid1c3 /dev/disk/by-id/ata-ST18000NM003D-3DL103_* -L array
    "/srv/nfs" = {
      device = "/dev/disk/by-label/array";
      fsType = "btrfs";
      options = [
        "subvol=nfs"
        "compress-force=zstd:3"
        "noatime"
      ];
    };
  };

  networking.firewall.interfaces.${config.services.tailscale.interfaceName}.allowedTCPPorts = [ config.services.prometheus.exporters.node.port ];

  services = {
    prometheus.exporters.node.enable = true;

    btrfs.autoScrub = {
      enable = true;

      interval = "monthly";
      fileSystems = [ "/srv/nfs" ];
    };

    hddfancontrol = {
      enable = true;

      pwmPaths = [ "/sys/class/hwmon/hwmon2/pwm2:128:0" ];

      disks = [
        "/dev/disk/by-path/platform-fd500000.pcie-pci-0000:01:00.0-ata-1.0"
        "/dev/disk/by-path/platform-fd500000.pcie-pci-0000:01:00.0-ata-2.0"
        "/dev/disk/by-path/platform-fd500000.pcie-pci-0000:01:00.0-ata-3.0"
        "/dev/disk/by-path/platform-fd500000.pcie-pci-0000:01:00.0-ata-4.0"
        "/dev/disk/by-path/platform-fd500000.pcie-pci-0000:01:00.0-ata-5.0"
      ];

      extraArgs = [
        "--min-fan-speed-prct=10"
        "--interval=1min"
      ];
    };
  };

  users.users.electro = {
    isNormalUser = true;
    uid = 1000;

    # Change password using:
    # $ nix run nixpkgs#mkpasswd -- -m SHA-512 -s
    hashedPasswordFile = config.sops.secrets.electroPassword.path;

    extraGroups = [
      "wheel" # allow using `sudo` for this user.
    ];

    openssh.authorizedKeys.keyFiles = [
      ../mercury/id_ed25519.pub
      ../terra/id_ed25519.pub
      ../venus/id_ed25519.pub
    ];
  };

  system.stateVersion = "24.05";
}
