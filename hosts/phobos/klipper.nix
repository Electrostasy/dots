{ config, pkgs, ... }:

{
  users = {
    groups.klipper = { };
    users.klipper = {
      isSystemUser = true;
      group = config.users.groups.klipper.name;
    };
  };

  services.klipper = {
    enable = true;

    user = "klipper";
    group = "klipper";

    configFile = ./mcu-prusa-mk3s.cfg;
  };

  environment.systemPackages = with pkgs; [
    # Expose klipper's calibrate_shaper.py because the klipper module does not.
    (writeShellApplication {
      name = "calibrate_shaper";
      runtimeInputs = [( python3.withPackages (ps: [ ps.numpy ps.matplotlib ]) )];
      text = "${klipper.src}/scripts/calibrate_shaper.py \"$@\"";
    })
  ];

  services.udev.extraRules = /* udev */ ''
    # In order to not have to use /dev/serial/by-id/usb-Prusa_Research__prus...
    # to communicate with the 3D printer's serial socket. This will symlink to
    # for e.g. /dev/ttyACM0.
    SUBSYSTEM=="tty", ATTRS{idVendor}=="2c99", ATTRS{idProduct}=="0002", SYMLINK+="ttyMK3S"

    # Setup Linux USB permissions for klipper to access MCUs over serial.
    SUBSYSTEM=="usb", DRIVER=="usb", MODE="0664", ATTR{idVendor}=="2109", GROUP="dialout"
    SUBSYSTEM=="usb", DRIVER=="usb", MODE="0664", ATTR{idVendor}=="1d6b", GROUP="dialout"

    # Work around libcamera dma_heap errors:
    # https://raspberrypi.stackexchange.com/a/141107.
    SUBSYSTEM=="dma_heap", GROUP="video", MODE="0660"
  '';

  systemd.services = {
    # RP2040-based secondary Klipper MCUs seem to be stuck in an error state on boot,
    # giving errors such as:
    # `usb 1-1.3: device descriptor read/64, error -32`
    # `usb 1-1.3: Device not responding to setup address.`
    # Power cycling them once on boot seems to fix it and allows the main Klipper
    # service to continue launch.
    klipper.postStart = "${pkgs.uhubctl}/bin/uhubctl --level 2 --action 2";

    # Set Mainsail theme from Moonraker as the default theme.
    moonraker.preStart = /* bash */ ''
      MAINSAIL_CONFIG='${config.services.moonraker.stateDir}/config/.theme/default.json'
      # If the symlink is broken, remove it first.
      if [ -h "$MAINSAIL_CONFIG" -a ! -e "$MAINSAIL_CONFIG" ]; then
        unlink "$MAINSAIL_CONFIG"
      else
        exit 0
      fi

      mkdir -p "''${MAINSAIL_CONFIG%/*}"
      ln -s ${./mainsail-config.json} "$MAINSAIL_CONFIG"
    '';
  };

  networking.firewall = {
    allowedTCPPorts = [ 80 8080 ];
    allowedUDPPorts = [ 80 8080 ];
  };

  # Grant the `moonraker` user access to the /run/klipper/api socket.
  users.users.moonraker.extraGroups = [ "klipper" ];

  security.polkit.enable = true;

  services = {
    mainsail = {
      enable = true;

      # For some reason, uploads bypass moonraker and we get hit with nginx's
      # `client intended to send too large body` error unless we increase the
      # upload size for mainsail in the server (does not work per location).
      nginx.extraConfig = ''
        client_max_body_size 1024m;
      '';
    };

    moonraker = {
      enable = true;
      allowSystemControl = true;

      settings = {
        history = { };
        authorization = {
          force_logins = true;
          cors_domains = [
            "*://localhost"
            "*://phobos"
          ];
          trusted_clients = [
            "127.0.0.1/32"
            "100.64.0.0/24"
          ];
        };
      };
    };
  };
}
