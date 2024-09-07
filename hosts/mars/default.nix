{ config, pkgs, lib, ... }:

{
  imports = [
    ../../profiles/minimal
    ../../profiles/shell
    ../../profiles/ssh
  ];

  nixpkgs = {
    hostPlatform = "aarch64-linux";

    # Needed for Rockchip TPL for RK3588 in u-boot.
    allowUnfreePackages = [ "rkbin" ];
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
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "console=ttyS0,1500000n8"
      "console=ttyAMA0,1500000n8"
      "console=tty0"
    ];

    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    mtdutils # flashcp
    pciutils # lspci
    usbutils # lsusb
  ];

  # TODO:
  # - On-board USB 3.0 Type-A does not work (unpowered?);
  # - On-board USB/DP 3.0 Type-C does not work (has power?);
  # - On-board USB 2.0 Type-A x2 does not work (unpowered?).
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
              spi-max-frequency = <50000000>;
              spi-rx-bus-width = <4>;
              spi-tx-bus-width = <1>;
            };
          };
        '';
      }

      # {
      #   name = "enable-usb3.0-port-overlay";
      #   dtsText = ''
      #     /dts-v1/;
      #     /plugin/;
      #
      #     #include <dt-bindings/gpio/gpio.h>
      #     #include <dt-bindings/pinctrl/rockchip.h>
      #
      #     / {
      #       compatible = "friendlyarm,nanopc-t6", "rockchip,rk3588";
      #
      #       vcc5v0_host_30: vcc5v0-host-30 {
      #         compatible = "regulator-fixed";
      #         enable-active-high;
      #         gpio = <&gpio4 RK_PB0 GPIO_ACTIVE_HIGH>;
      #         pinctrl-names = "default";
      #         pinctrl-0 = <&vcc5v0_host30_en>;
      #         regulator-min-microvolt = <5000000>;
      #         regulator-max-microvolt = <5000000>;
      #         regulator-name = "vcc5v0_host_30";
      #         vin-supply = <&vcc5v0_sys>;
      #       };
      #     };
      #
      #     &pinctrl {
      #       usb {
      #         vcc5v0_host30_en: vcc5v0-host30-en {
      #           rockchip,pins = <4 RK_PB0 RK_FUNC_GPIO &pcfg_pull_none>;
      #         };
      #       };
      #     };
      #
      #     &u2phy1 {
      #       status = "okay";
      #     };
      #
      #     &u2phy1_otg {
      #       phy-supply = <&vcc5v0_host_30>;
      #       status = "okay";
      #     };
      #
      #     &usbdp_phy1 {
      #       status = "okay";
      #     };
      #
      #     &usb_host1_xhci {
      #       dr_mode = "host";
      #       status = "okay";
      #     };
      #   '';
      # }
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
      options = [
        "fmask=0022"
        "dmask=0022"
      ];
    };
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

  users = {
    mutableUsers = false;
    users.electro = {
      isNormalUser = true;
      hashedPasswordFile = config.sops.secrets.electroPassword.path;
      extraGroups = [ "wheel" ];
      uid = 1000;
      openssh.authorizedKeys.keyFiles = [
        ../mercury/id_ed25519.pub
        ../terra/id_ed25519.pub
        ../venus/id_ed25519.pub
      ];
    };
  };

  system.stateVersion = "24.11";
}
