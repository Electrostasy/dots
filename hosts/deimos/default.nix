{ config, pkgs, ... }:

{
  imports = [
    ../../profiles/minimal.nix
    ../../profiles/shell.nix
    ../../profiles/ssh
    ../../profiles/tailscale.nix
    ./klipper.nix
  ];

  nixpkgs.hostPlatform.system = "aarch64-linux";

  image.modules.default.imports = [
    ../../profiles/image/expand-root.nix
    ../../profiles/image/generic-efi.nix
    ../../profiles/image/interactive.nix
    ../../profiles/image/platform/raspberrypi-zero-2-w.nix
  ];

  sops = {
    defaultSopsFile = ./secrets.yaml;

    secrets = {
      networkmanager = {};
      electroPassword.neededForUsers = true;
      electroIdentity = {
        mode = "0400";
        owner = config.users.users.electro.name;
      };
    };
  };

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

    ensureProfiles = {
      environmentFiles = [ config.sops.secrets.networkmanager.path ];

      profiles = {
        home-wifi = {
          connection = {
            id = "home";
            type = "wifi";
            autoconnect = true;
            autoconnect-retries = 0;
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
            autoconnect-retries = 0;
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

  users.users.electro = {
    isNormalUser = true;
    uid = 1000;

    # Change password using:
    # $ nix run nixpkgs#mkpasswd -- -m SHA-512 -s
    hashedPasswordFile = config.sops.secrets.electroPassword.path;

    extraGroups = [ "wheel" ];

    openssh.authorizedKeys.keyFiles = [
      ../mercury/id_ed25519.pub
      ../terra/id_ed25519.pub
      ../venus/id_ed25519.pub
    ];
  };

  system.stateVersion = "25.11";
}
