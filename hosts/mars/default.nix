{ config, pkgs, lib, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/profiles/minimal.nix"
    ../../profiles/shell
    ../../profiles/ssh
  ];

  nixpkgs = {
    hostPlatform = "aarch64-linux";

    # Needed for Rockchip TPL for RK3588 in u-boot.
    allowUnfreePackages = [ "rkbin" ];
  };

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

  system = {
    checks = [ config.system.build.uboot ];

    build.uboot = pkgs.ubootNanoPCT6.override (oldAttrs: {
      # Include the SPI NOR flash build artifact.
      filesToInstall = oldAttrs.filesToInstall ++ [ "u-boot-rockchip-spi.bin" ];

      # Use blobless Boot Loader stage 3.1. For some reason, the ATF packages
      # do not have an `override` function, so we have to use `overrideAttrs`.
      BL31 = "${pkgs.armTrustedFirmwareRK3588.overrideAttrs {
        platformCanUseHDCPBlob = false;

        meta.license = lib.licenses.bsd3;
      }}/bl31.elf";
    });
  };

  boot = {
    loader.generic-extlinux-compatible.enable = true;

    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      # Enable serial console over USB-C debug UART port.
      "8250.nr_uarts=1"
      "console=ttyS0,1500000"
    ];
  };

  environment.systemPackages = with pkgs; [
    mtdutils # `flashcp`.
    pciutils # `lspci`.
    usbutils # `lsusb`.
  ];

  # TODO: Remove in Linux 6.12, as NanoPC-T6 LTS got official support:
  # https://lkml.org/lkml/2024/9/16/842
  hardware.deviceTree = {
    filter = "rk3588-nanopc-t6.dtb";
    overlays = [
      {
        name = "enable-sfc-spi-nor-overlay";
        dtsText = ''
          /dts-v1/;
          /plugin/;

          / {
            compatible = "friendlyarm,nanopc-t6", "rockchip,rk3588";
          };

          &sfc {
            status = "okay";

            spi_flash: spi-flash@0 {
              compatible = "jedec,spi-nor";
              reg = <0>;
              spi-max-frequency = <104000000>;
              spi-rx-bus-width = <4>;
              spi-tx-bus-width = <1>;
            };
          };
        '';
      }
    ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-partlabel/nixos";
      fsType = "ext4";
      options = [ "defaults" ];
    };

    "/boot" = {
      device = "/dev/disk/by-partlabel/boot";
      fsType = "vfat";
      options = [ "umask=0077" ];
    };
  };

  systemd.network.networks."40-wired" = {
    name = "en*";
    networkConfig.DHCP = true;
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

  system.stateVersion = "24.11";
}
