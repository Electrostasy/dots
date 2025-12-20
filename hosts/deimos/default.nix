{ config, pkgs, lib, ... }:

{
  imports = [
    ../../profiles/minimal.nix
    ../../profiles/shell
    ../../profiles/ssh
    ../../profiles/tailscale.nix
  ];

  nixpkgs = {
    hostPlatform.system = "aarch64-linux";

    overlays = [
      # Klipper NixOS module flash scripts do not work/build.
      (final: prev: {
        klipper-flash-einsy-rambo =
          let
            firmware = (prev.klipper-firmware.overrideAttrs (prevAttrs: {
              buildFlags = [ "out/klipper.elf.hex" ];
              installPhase = prevAttrs.installPhase + ''
                cp out/klipper.elf.hex $out/ || true
              '';
            })).override {
              klipper = config.services.klipper.package;
              mcu = "prusa-mk3s";
              firmwareConfig = ./configs/einsy-rambo.config;
            };
          in
            prev.writeShellApplication {
              name = "klipper-flash-einsy-rambo";

              runtimeInputs = [ prev.avrdude ];
              runtimeEnv = { inherit firmware; };
              passthru = { inherit firmware; };

              text = ''
                avrdude -cwiring -patmega2560 -P"$1" -b115200 -D -Uflash:w:$firmware/klipper.elf.hex:i
              '';
            };

        klipper-flash-rp2040 =
          let
            firmware = (prev.klipper-firmware.overrideAttrs (prevAttrs: {
              buildFlags = [ "out/klipper.uf2" "lib/rp2040_flash/rp2040_flash" ];
              installPhase = prevAttrs.installPhase + ''
                cp lib/rp2040_flash/rp2040_flash $out/ || true
              '';
            })).override {
              klipper = config.services.klipper.package;
              mcu = "led-controller";
              firmwareConfig = ./configs/rp2040.config;
            };
          in
            prev.writeShellApplication {
              name = "klipper-flash-rp2040";

              runtimeEnv = { inherit firmware; };
              passthru = { inherit firmware; };

              text = ''
                $firmware/rp2040_flash $firmware/klipper.uf2
              '';
            };
          })
    ];
  };

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
      {
        name = "usb-host-overlay";
        dtsFile = ./usb-host.dtso;
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

  systemd.tmpfiles.settings."10-klipper".${config.services.klipper.configDir} = {
    # Our Klipper config consists of multiple files while the Klipper NixOS
    # module expects and moves only the specified configFile to the configDir.
    # The entire config must be copied to the configDir.
    # We cannot use symlinks as Klipper will throw a "too many links" error.
    "C+" = {
      mode = "0644";
      user = config.users.users.moonraker.name;
      group = config.users.groups.moonraker.name;
      argument = "${./klipper}";
    };

    # Remove the configdir and all its contents. Without this rule present, the
    # config will not be updated on activation if the config files are already
    # present.
    "R" = { };

    # Create the config dir with the correct permissions.
    "d" = {
      mode = "0755";
      user = config.users.users.moonraker.name;
      group = config.users.groups.moonraker.name;
    };
  };

  systemd.services.klipper = {
    wants = [ "systemd-tmpfiles-setup.service" ];
    after = [ "systemd-tmpfiles-setup.service" ];

    # Prevent the service from creating an empty printer.cfg on startup.
    preStart = lib.mkForce "";
  };

  services.klipper = {
    enable = true;

    # Install Klipper with plugins.
    # package = pkgs.klipper.overrideAttrs (oldAttrs: {
    #   postInstall = ''
    #     ${oldAttrs.postInstall or ""}
    #
    #     chmod +w $out/lib/klippy/extras
    #     cp -rvT ${pkgs.klipper_tmc_autotune} $out
    #   '';
    # });

    # Allow Moonraker to control Klipper.
    user = config.users.users.moonraker.name;
    group = config.users.groups.moonraker.name;

    configFile = "${config.services.klipper.configDir}/printer.cfg";
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
    config.services.klipper.package # adds `klipper-calibrate-shaper`.
    pkgs.klipper-flash-einsy-rambo
    pkgs.klipper-flash-rp2040
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
