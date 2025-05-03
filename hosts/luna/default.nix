{ config, pkgs, lib, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/profiles/minimal.nix"
    ../../profiles/shell
    ../../profiles/ssh
    ../../profiles/tailscale.nix
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

  boot = {
    loader.generic-extlinux-compatible.enable = true;

    kernelPackages = pkgs.linuxPackages_latest;

    blacklistedKernelModules = [
      # We use emc230x instead, added below.
      "emc2305"
    ];

    extraModulePackages = [
      (pkgs.emc230x.override { linuxPackages = config.boot.kernelPackages; })
    ];

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

  # NOTE: If the device tree changes, it needs to be re-added into the /boot
  # directory where the firmware lives:
  # https://forums.raspberrypi.com/viewtopic.php?t=370304#p2227480
  hardware.deviceTree = {
    filter = "bcm2711-rpi-cm4-io.dtb";

    overlays = [
      {
        name = "usb3-overlay";
        dtsText = ''
          /dts-v1/;
          /plugin/;

          / {
            compatible = "raspberrypi,4-compute-module", "brcm,bcm2711";
          };

          &xhci {
            status = "okay";
          };
        '';
      }

      # TODO: Driver probe fails.
      # {
      #   name = "rtc-overlay";
      #   dtsText = ''
      #     /dts-v1/;
      #     /plugin/;
      #
      #     / {
      #       compatible = "raspberrypi,4-compute-module", "brcm,bcm2711";
      #     };
      #
      #     &i2c0_1 {
      #       rtc@51 {
      #         status = "disabled";
      #       };
      #
      #       rtc@52 {
      #         compatible = "microcrystal,rv3028";
      #         reg = <0x52>;
      #       };
      #     };
      #   '';
      # }

      {
        name = "fan-control-overlay";
        dtsText = ''
          /dts-v1/;
          /plugin/;

          #include <dt-bindings/thermal/thermal.h>

          / {
            compatible = "raspberrypi,4-compute-module", "brcm,bcm2711";
          };

          &i2c0_0 {
            fan_controller: fan-controller@2e {
              reg = <0x2e>;
              compatible = "microchip,emc2305";
              #address-cells = <1>;
              #size-cells = <0>;

              // RPM values taken from Noctua NF-A4x20 PWM specifications:
              // https://noctua.at/en/nf-a4x20-pwm
              fan0: fan@0 {
                reg = <0>;
                min-rpm = /bits/ 16 <1200>;
                max-rpm = /bits/ 16 <5000>;
                #cooling-cells = <2>;
              };
            };
          };

          // These are the same trips and cooling-maps as in the Raspberry Pi
          // downstream's bcm2712-rpi-5-b.dts.
          &cpu_thermal {
            trips {
              cpu_tepid: cpu-tepid {
                temperature = <50000>;
                hysteresis = <2000>;
                type = "active";
              };

              cpu_warm: cpu-warm {
                temperature = <60000>;
                hysteresis = <2000>;
                type = "active";
              };

              cpu_hot: cpu-hot {
                temperature = <67500>;
                hysteresis = <2000>;
                type = "active";
              };

              cpu_vhot: cpu-vhot {
                temperature = <75000>;
                hysteresis = <2000>;
                type = "active";
              };

              cpu_crit: cpu-crit {
                temperature = <90000>;
                hysteresis = <0>;
                type = "critical";
              };
            };

            cooling-maps {
              tepid {
                trip = <&cpu_tepid>;
                cooling-device = <&fan0 0 3>;
              };

              warm {
                trip = <&cpu_warm>;
                cooling-device = <&fan0 4 5>;
              };

              hot {
                trip = <&cpu_hot>;
                cooling-device = <&fan0 5 6>;
              };

              vhot {
                trip = <&cpu_vhot>;
                cooling-device = <&fan0 6 7>;
              };

              melt {
                trip = <&cpu_crit>;
                cooling-device = <&fan0 7 THERMAL_NO_LIMIT>;
              };
            };
          };
        '';
      }
    ];
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

  networking.firewall = {
    interfaces.${config.services.tailscale.interfaceName}.allowedTCPPorts = [ config.services.prometheus.exporters.node.port ];

    # Required for NFS3/4.
    allowedTCPPorts = [ 111 2049 4000 4001 4002 20048 ];
    allowedUDPPorts = [ 111 2049 4000 4001 4002 20048 ];
  };

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

    nfs = {
      server = {
        enable = true;

        exports = ''
          /srv/nfs/ *.sol.tailnet.${config.networking.domain}(rw,fsid=root,insecure)
          /srv/nfs/ 192.168.205.0/24(rw,fsid=0,insecure)
        '';
      };

      settings.nfsd = {
        vers2 = false;
        vers3 = true; # needed for mounting by Windows clients.
      };
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
