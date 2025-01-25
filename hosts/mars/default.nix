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

  system = {
    checks = [ config.system.build.uboot ];

    build.uboot = pkgs.ubootNanoPCT6.override (oldAttrs: {
      version = "2025.01-rc2";

      # 2025.01 contains the NanoPC-T6 LTS DTB using the same defconfig. This will
      # allow loading the correct DTB during boot.
      src = pkgs.fetchurl {
        url = "https://ftp.denx.de/pub/u-boot/u-boot-2025.01-rc2.tar.bz2";
        hash = "sha256-RVaXQ+3SJaKf50OdejBbmzEI+yYF6Zwad6+B/PQhVJo=";
      };

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
