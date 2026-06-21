{ config, ... }:

{
  hardware.deviceTree.overlays = [
    {
      name = "usb-host-overlay";
      dtsFile = ./usb-host.dtso;
    }
  ];

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

    firmwares = {
      mcu = {
        enable = true;
        enableKlipperFlash = true;

        serial = "/dev/serial/by-path/platform-3f980000.usb-usb-0:1.1:1.0";

        configFile = ./configs/einsy-rambo.config;
      };

      adxl_controller = {
        enable = true;
        enableKlipperFlash = true;

        serial = "/dev/serial/by-path/platform-3f980000.usb-usb-0:1.3:1.0";
        configFile = ./configs/rp2040.config;
      };

      ext_controller = {
        enable = true;
        enableKlipperFlash = true;

        serial = "/dev/serial/by-path/platform-3f980000.usb-usb-0:1.4:1.0";
        configFile = ./configs/rp2040.config;
      };
    };

    # Allow Moonraker to control Klipper.
    mutableConfig = true;
    configDir = "${config.services.moonraker.stateDir}/config";
    configFile = "${config.services.moonraker.stateDir}/config/printer.cfg";
    user = config.users.users.moonraker.name;
    group = config.users.groups.moonraker.name;
  };

  # Required for Moonraker's allowSystemControl.
  security.polkit.enable = true;

  services.moonraker = {
    enable = true;
    analysis.enable = true;

    allowSystemControl = true;

    settings = {
      history = { };
      authorization = {
        force_logins = true;
        cors_domains = [
          "*://localhost"
          "*://${config.networking.hostName}"

          # Tailscale MagicDNS.
          "*://${config.networking.hostName}.sol.tailnet.0x6776.lt"
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
  ];
}
