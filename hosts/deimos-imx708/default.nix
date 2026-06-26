{ config, pkgs, modulesPath, flake, ... }:

{
  imports = [
    "${modulesPath}/profiles/minimal.nix"
    ../../profiles/shell.nix
    ../../profiles/ssh.nix
    ../../profiles/users/electro
    ../../profiles/zramswap.nix
  ];

  nixpkgs.hostPlatform.system = "aarch64-linux";

  nixpkgs.overlays = [ flake.outputs.overlays.imx708 ];

  image.modules.default.imports = [
    ../../profiles/image/expand-root.nix
    ../../profiles/image/generic-efi.nix
    ../../profiles/image/hybrid-mbr.nix
    ../../profiles/image/platform/raspberrypi-zero-2-w.nix
  ];

  sops.secrets.networkmanager = { };

  hardware.deviceTree = {
    name = "broadcom/bcm2837-rpi-zero-2-w.dtb";

    overlays = [
      {
        name = "imx708-overlay";
        dtsFile = ./imx708-overlay.dtso;
      }
    ];
  };

  boot = {
    loader.systemd-boot.enable = true;

    kernelParams = [ "8250.nr_uarts=1" ];

    extraModulePackages = [
      config.boot.kernelPackages.dw9807-vcm
      config.boot.kernelPackages.imx708
    ];

    initrd = {
      systemd.root = "gpt-auto";
      supportedFilesystems.ext4 = true;
    };
  };

  services.journald.storage = "volatile";

  # Required for Wi-Fi.
  hardware.firmware = [ pkgs.raspberrypiWirelessFirmware ];

  networking.firewall = {
    allowedTCPPorts = [ 8080 ];
    allowedUDPPorts = [ 8080 ];
  };

  networking.networkmanager = {
    enable = true;

    wifi = {
      scanRandMacAddress = false;
      powersave = false;
    };

    ensureProfiles = {
      environmentFiles = [ config.sops.secrets.networkmanager.path ];

      profiles = {
        home-wifi = {
          connection = {
            id = "home";
            type = "wifi";
            autoconnect = true;
          };

          wifi = {
            ssid = "$SSID_HOME_WIFI";
            mode = "infrastructure";
          };

          wifi-security = {
            key-mgmt = "wpa-psk";
            psk = "$PSK_HOME_WIFI";
          };
        };

        phobos-wifi = {
          connection = {
            id = "home_ap";
            type = "wifi";
            autoconnect = true;
          };

          wifi = {
            ssid = "$SSID_PHOBOS_WIFI";
            mode = "infrastructure";
          };

          wifi-security = {
            key-mgmt = "wpa-psk";
            psk = "$PSK_PHOBOS_WIFI";
          };
        };
      };
    };
  };

  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = [
    pkgs.v4l-utils
    pkgs.libcamera
    pkgs.i2c-tools
    pkgs.dtc
    pkgs.libgpiod
  ];

  system.stateVersion = "26.11";
}
