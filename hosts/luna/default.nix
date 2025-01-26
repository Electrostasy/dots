{ config, pkgs, lib, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/profiles/minimal.nix"
    ../../profiles/shell
    ../../profiles/ssh
  ];

  nixpkgs.hostPlatform = "aarch64-linux";

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

    # To update the modconfig run: `ARCH=arm64 make oldconfig`
    kernelPackages = pkgs.linuxPackages_custom {
      inherit (pkgs.linuxPackages_latest.kernel) version src;
      configfile = ./modconfig;
    };

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
        # If our array cannot be mounted due to a failed disk or some other
        # reason, we need a way to get in and fix it.
        emergencyAccess = true;

        # TPM is explicitly disabled in the kernel config, but the kernel build
        # will fail due to missing `tpm-crb` kernel module unless we disable it
        # in initrd too.
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

  hardware.deviceTree = {
    filter = "bcm2711-rpi-cm4-io.dtb";
    overlays = [
      {
        # Cut down version of the Interceptor device tree in overlay form
        # without support for the PoE boards.
        name = "axzez-interceptor-overlay";
        dtsText = ''
          /dts-v1/;
          /plugin/;

          / {
            compatible = "raspberrypi,4-compute-module", "brcm,bcm2711";
          };

          &xhci {
            status = "okay";
          };

          &gpio {
            spi0_pins: spi0_pins {
              brcm,pins = <0x28 0x29 0x2a>;
              brcm,function = <0x03>;
            };

            spi0_cs_pins: spi0_cs_pins {
              brcm,pins = <0x2b>;
              brcm,function = <0x01>;
            };
          };

          &spi {
            status = "okay";
            pinctrl-names = "default";
            pinctrl-0 = <&spi0_pins &spi0_cs_pins>;
            cs-gpios = <&gpio 0x2b 0x01>;

            spidev@0 {
              compatible = "jedec,spi-nor";
              reg = <0x00>;
              spi-max-frequency = <0x989680>;
            };
          };

          &i2c0 {
            rv3028@52 {
              compatible = "microcrystal,rv3028";
              reg = <0x52>;
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

    # Filesystem creation command used:
    # $ mkfs.btrfs -d raid6 -m raid1c3 /dev/sd{a..e} -L array
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

  networking.firewall.allowedTCPPorts = [ 2049 ];

  services = {
    rpcbind.enable = lib.mkForce false; # not needed for NFSv4.

    btrfs.autoScrub = {
      enable = true;

      interval = "monthly";
      fileSystems = [ "/srv/nfs" ];
    };

    nfs = {
      server = {
        enable = true;
        createMountPoints = true;
        exports = ''
          /srv/nfs/ *.sol.${config.networking.domain}(rw,fsid=root,insecure)
        '';
      };

      settings.nfsd = {
        vers2 = false;
        vers3 = false;
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
