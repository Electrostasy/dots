{ config, pkgs, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/profiles/minimal.nix"
    ../../profiles/shell.nix
    ../../profiles/ssh.nix
    ../../profiles/users/electro
    ../../profiles/zramswap.nix
    ./kernel.nix
  ];

  nixpkgs.hostPlatform.system = "aarch64-linux";

  image.modules.default.imports = [
    ../../profiles/image/expand-root.nix
    ../../profiles/image/generic-efi.nix
    ../../profiles/image/hybrid-mbr.nix
    ../../profiles/image/platform/raspberrypi-zero-2-w.nix
  ];

  sops.secrets.networkmanager = { };

  hardware.deviceTree.name = "broadcom/bcm2837-rpi-zero-2-w.dtb";

  boot = {
    loader.systemd-boot.enable = true;

    kernelParams = [ "8250.nr_uarts=1" ];

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

  system.stateVersion = "26.11";
}
