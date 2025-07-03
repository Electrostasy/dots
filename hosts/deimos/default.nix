{ config, pkgs, ... }:

{
  imports = [
    ../../profiles/minimal.nix
    ../../profiles/shell
    ../../profiles/ssh
    ../../profiles/tailscale.nix
  ];

  nixpkgs.hostPlatform.system = "aarch64-linux";

  image.modules.default.imports = [
    ../../profiles/image/expand-root.nix
    ./image.nix
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
      {
        name = "disable-bt-overlay";
        dtsFile = ./disable-bt.dts;
      }
      {
        name = "usb-host-overlay";
        dtsFile = ./usb-host.dts;
      }
    ];
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = false;
    };

    initrd.systemd.root = "gpt-auto";
    supportedFilesystems.ext4 = true;
  };

  zramSwap.enable = true;

  # Required for Wi-Fi.
  hardware.firmware = [ pkgs.raspberrypiWirelessFirmware ];

  networking.firewall = {
    allowedTCPPorts = [ 80 443 ];
    allowedUDPPorts = [ 80 443 ];
  };

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
            id = "work";
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

  services.udev.extraRules = /* udev */ ''
    # In order to not have to use /dev/serial/by-id/usb-Prusa_Research__prus...
    # to communicate with the 3D printer over serial.
    SUBSYSTEM=="tty", ATTRS{idVendor}=="2c99", ATTRS{idProduct}=="0002", SYMLINK+="ttyMK3S"
  '';

  services.klipper = {
    enable = true;

    # Allow Moonraker to control Klipper.
    user = config.users.users.moonraker.name;
    group = config.users.groups.moonraker.name;

    configFile = ./mcu-prusa-mk3s.cfg;
  };

  # Required for Moonraker's allowSystemControl.
  security.polkit.enable = true;

  services.moonraker = {
    enable = true;

    allowSystemControl = true;

    settings = {
      history = { };
      authorization = {
        force_logins = true;
        cors_domains = [
          "*://localhost"
          "*://${config.networking.hostName}"

          # Tailscale MagicDNS.
          "*://${config.networking.hostName}.sol.tailnet.${config.networking.domain}"
        ];
        trusted_clients = [
          "127.0.0.1/32"
          "100.64.0.0/24"
        ];
      };
    };
  };

  services.mainsail = {
    enable = true;

    nginx.extraConfig = ''
      # Allow sending gcode files up to 1G.
      client_max_body_size 1024m;
    '';
  };

  services.journald.storage = "volatile";

  environment.systemPackages = [
    # Expose klipper's calibrate_shaper.py for input shaper calibration.
    (pkgs.writeShellApplication {
      name = "calibrate_shaper";
      runtimeInputs = [ (pkgs.python3.withPackages (ps: with ps; [ numpy matplotlib ])) ];
      text = "${config.services.klipper.package.src}/scripts/calibrate_shaper.py \"$@\"";
    })
  ];

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

  system.stateVersion = "25.11";
}
