{ config, flake, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/profiles/minimal.nix"
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
      flake.outputs.overlays.emc2305-patched
    ];
  };

  image.modules.default.imports = [
    ../../profiles/image/expand-root.nix
    ../../profiles/image/generic-efi.nix
    ../../profiles/image/platform/raspberrypi-cm4.nix
  ];

  # An Axzez (now Exaviz) Interceptor carrier board v1.0 for the Raspberry Pi
  # Compute Module 4 is used.
  hardware.deviceTree = {
    # There is no open source devicetree for this carrier board, but the vendor
    # devicetree when decompiled is very similar to the official Raspberry Pi
    # Compute Module 4 IO Board, so it is extended with overlays.
    name = "broadcom/bcm2711-rpi-cm4-io.dtb";

    overlays = [
      # Enable the on-board USB ports by enabling the xHCI controller.
      {
        name = "enable-xhci-overlay";
        dtsFile = ./enable-xhci.dtso;
      }

      # Add external PWM fan control controlled with I²C on the J9 FFC
      # connector because the on-board Molex KK 254 3 pin fan headers do not
      # support PWM fan control.
      {
        name = "fan-control-overlay";
        dtsFile = ./fan-control.dtso;
      }

      # Fix SATA drives connected to the on-board JMB585 SATA-PCIe bridge not
      # being found on Linux 6.18.24 or later by dropping the DMA ranges down
      # to 2 GB. Since 6.18.24, JMB585 is forced into 32-bit DMA because 64-bit
      # DMA is broken and Raspberry Pi has issues with 32-bit DMA:
      # https://github.com/artmoty-dev/n5pro-jmb585-fix#whats-happening
      # https://github.com/raspberrypi/linux/issues/4848#issuecomment-1028191675
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

  systemd.network.networks."40-dhcp-ipv4-only" = {
    matchConfig.Name = "en*";
    networkConfig = {
      DHCP = "ipv4";
      IPv6AcceptRA = "no";
      LinkLocalAddressing = "no";
    };
  };

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
