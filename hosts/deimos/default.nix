{ config, pkgs, ... }:

{
  imports = [
    ../../profiles/minimal.nix
    ../../profiles/shell.nix
    ../../profiles/ssh.nix
    ../../profiles/tailscale.nix
    ../../users/electro
    ./klipper.nix
  ];

  nixpkgs.hostPlatform.system = "aarch64-linux";

  image.modules.default.imports = [
    ../../profiles/image/expand-root.nix
    ../../profiles/image/generic-efi.nix
    ../../profiles/image/interactive.nix
    ../../profiles/image/platform/raspberrypi-zero-2-w.nix
  ];

  sops.secrets.networkmanager = { };

  hardware.deviceTree = {
    name = "broadcom/bcm2837-rpi-zero-2-w.dtb";

    overlays = [
      # {
      #   name = "disable-bt-overlay";
      #   dtsFile = ./disable-bt.dtso;
      # }
    ];
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = false;
    };

    kernelParams = [ "8250.nr_uarts=1" ];

    initrd = {
      systemd = {
        root = "gpt-auto";
        tpm2.enable = false;
      };

      supportedFilesystems.ext4 = true;
    };
  };

  zramSwap.enable = true;

  services.journald.storage = "volatile";

  networking.firewall.interfaces.${config.services.tailscale.interfaceName} = {
    allowedTCPPorts = [ 80 443 ];
    allowedUDPPorts = [ 80 443 ];
  };

  # Required for Wi-Fi.
  hardware.firmware = [ pkgs.raspberrypiWirelessFirmware ];

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

  system.stateVersion = "25.11";
}
