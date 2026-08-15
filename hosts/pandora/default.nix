{ config, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/profiles/minimal.nix"
    ../../profiles/common.nix
    ../../profiles/networking.nix
    ../../profiles/shell.nix
    ../../profiles/ssh.nix
    ../../profiles/tailscale.nix
    ../../profiles/telemetry.nix
    ../../profiles/users/electro
    ../../profiles/users/sukceno
    ../../profiles/zramswap.nix
    ./nfs.nix
    ./samba.nix
  ];

  nixpkgs = {
    hostPlatform.system = "aarch64-linux";
    overlays = [
      (import ../../overlays/emc2305-patched)
    ];
  };

  image.modules.default.imports = [
    ../../profiles/image/expand-root.nix
    ../../profiles/image/generic-efi.nix
    ../../profiles/image/platform/raspberrypi-cm4.nix
  ];

  hardware.deviceTree = {
    # There is no open source devicetree for this Exaviz Interceptor carrier
    # board v1.0 for the Raspberry Pi Compute Module 4. The decompiled vendor
    # devicetree is the most similar to the Raspberry Pi Compute Module 4 IO
    # Board, so it is used as the base instead.
    name = "broadcom/bcm2711-rpi-cm4-io.dtb";

    overlays = [
      {
        name = "enable-xhci-overlay";
        dtsFile = ./enable-xhci.dtso;
      }
      {
        name = "rtc-overlay";
        dtsFile = ./rtc.dtso;
      }
      {
        name = "fan-control-overlay";
        dtsFile = ./fan-control.dtso;
      }
      {
        name = "pcie-32bit-dma-overlay";
        dtsFile = ./pcie-32bit-dma.dtso;
      }
    ];
  };

  boot = {
    loader.systemd-boot.enable = true;

    kernelParams = [ "8250.nr_uarts=1" ];

    # Shadow the built-in emc2305 driver with our patched one due to various
    # issues with it upstream.
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

  # Formatted from 5 disks using:
  # $ mkfs.btrfs -d raid6 -m raid1c3 /dev/disk/by-id/ata-ST18000NM003D-3DL103_* -L array
  # $ btrfs property set /mnt/array compression zstd:3
  fileSystems."/mnt/array" = {
    device = "/dev/disk/by-label/array";
    fsType = "btrfs";
    options = [ "noatime" ];
  };

  networking.hostName = "pandora";

  services = {
    journald = {
      storage = "volatile";

      upload = {
        enable = true;

        settings.Upload.URL = "http://phobos.sol.tailnet.0x6776.lt";
      };
    };

    btrfs.autoScrub = {
      enable = true;

      interval = "monthly";
      fileSystems = [ "/mnt/array" ];
    };

    smartd = {
      enable = true;

      # Schedule a short self-test every Saturday from 05:00 and a long
      # self-test every month on the 28th from midnight.
      defaults.monitored = "-a -n standby -s (S/../../6/05|L/../28/./00)";
      devices = [
        { device = "/dev/disk/by-path/platform-fd500000.pcie-pci-0000:01:00.0-ata-1.0"; }
        { device = "/dev/disk/by-path/platform-fd500000.pcie-pci-0000:01:00.0-ata-2.0"; }
        { device = "/dev/disk/by-path/platform-fd500000.pcie-pci-0000:01:00.0-ata-3.0"; }
        { device = "/dev/disk/by-path/platform-fd500000.pcie-pci-0000:01:00.0-ata-4.0"; }
        { device = "/dev/disk/by-path/platform-fd500000.pcie-pci-0000:01:00.0-ata-5.0"; }
      ];
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

  system.stateVersion = "24.05";
}
