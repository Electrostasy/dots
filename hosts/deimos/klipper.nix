{ config, pkgs, lib, ... }:

{
  nixpkgs.overlays = [
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

  hardware.deviceTree.overlays = [
    {
      name = "usb-host-overlay";
      dtsFile = ./usb-host.dtso;
    }
  ];

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

  services.fluidd = {
    enable = true;

    nginx.extraConfig = ''
      # Allow sending gcode files up to 1G.
      client_max_body_size 1024m;
    '';
  };

  environment.systemPackages = [
    config.services.klipper.package # adds `klipper-calibrate-shaper`.
    pkgs.klipper-flash-einsy-rambo
    pkgs.klipper-flash-rp2040
  ];
}
