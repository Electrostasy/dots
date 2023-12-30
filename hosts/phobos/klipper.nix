{ config, pkgs, lib, self, ... }:

{
  imports = [ self.inputs.nixos-hardware.nixosModules.raspberry-pi-4 ];

  hardware = {
    # fdtoverlay can't merge some Raspberry Pi overlays (errors out with
    # FDT_ERR_NOTFOUND),  as hardware.deviceTree is not RPi specific, but
    # Raspberry Pi's own dtmerge can, so this is the only way to use device
    # tree overlays on RPi in NixOS and U-Boot.
    raspberry-pi."4".apply-overlays-dtmerge.enable = true;

    deviceTree = {
      enable = true;

      filter = "bcm2711-rpi-4-b.dtb";
      # Raspberry Pi overlays are all hard-coded for BCM2835 (base architecture
      # for the Raspberry Pi SOCs), which means that they are compatible with
      # all BCM2835 derived SoCs (BCM2835, BCM2836, BCM2837, BCM2711).

      # All Raspberry Pi computers report the CPU as BCM2835 due to a choice made
      # by the Linux kernel developers. The Pi 4 is actually a BCM2711, as is
      # evident in its binary DTB "compatible" field:
      # 'compatible = "raspberrypi,4-model-b\0brcm,bcm2711";'

      # When NixOS merges overlays based on the "compatible" string with a binary
      # DTB file, if the "compatible" string in overlays does not explicitly match
      # the name of the device tree binary DTB, U-Boot will not load the DTB with
      # the merged overlays because they are not applied:
      # 'Skipping overlay imx708.dtbo: incompatible with bcm2711-rpi-4-b.dtb'
      # 'Applying overlay vc4-kms-v3d-pi4.dtbo to bcm2711-rpi-4-b.dtb... ok'
      # The Pi overlays have a compatible field of:
      # 'compatible = "brcm,bcm2835";'

      # RPi without U-Boot has some internal wizardry to merge overlays on boot,
      # which U-Boot does not do, so we need this special handling here.

      # More reading:
      # https://forums.raspberrypi.com/viewtopic.php?t=245384
      # https://forums.raspberrypi.com/viewtopic.php?t=307802
      # https://forums.raspberrypi.com/viewtopic.php?t=344826
      # https://forums.raspberrypi.com/viewtopic.php?t=353577
      overlays =
        let
          mkCompatibleDtsFile = dtbo:
            let
              drv = pkgs.runCommand "fix-dts" { nativeBuildInputs = with pkgs; [ dtc gnused ]; } ''
                mkdir "$out"
                dtc -I dtb -O dts ${dtbo} | sed -e 's/bcm2835/bcm2711/' > $out/overlay.dts
              '';
            in
              "${drv}/overlay.dts";

          inherit (config.boot.kernelPackages) kernel;
        in
          [
            {
              name = "imx708.dtbo";
              dtsFile = mkCompatibleDtsFile "${kernel}/dtbs/overlays/imx708.dtbo";
            }
            {
              name = "vc4-kms-v3d-pi4.dtbo";
              dtsFile = mkCompatibleDtsFile "${kernel}/dtbs/overlays/vc4-kms-v3d-pi4.dtbo";
            }
          ];
    };
  };

  boot = {
    # We depend on hardware supported only by the downstream Pi kernels, namely
    # the Raspberry Pi Camera Module 3 (Sony IMX708), for which the driver has
    # not reached upstream yet:
    # https://patchwork.kernel.org/project/linux-media/list/?series=715172&archive=both
    kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;
    kernelParams = [ "cma=512M" ];
  };

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
    # Set Mainsail theme from Moonraker as the default theme.
    moonraker.preStart = /* bash */ ''
      MAINSAIL_CONFIG='${config.services.moonraker.stateDir}/config/.theme/default.json'
      if [ ! -f "$MAINSAIL_CONFIG" ]; then
        mkdir -p "''${MAINSAIL_CONFIG%/*}"
        ln -s ${./mainsail-config.json} "$MAINSAIL_CONFIG"
      fi
    '';

    camera-streamer = {
      description = "Raspberry Pi Camera Module 3 Web Stream";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      unitConfig.ConditionPathExists = "/sys/bus/i2c/drivers/imx708/10-001a/video4linux";

      serviceConfig = {
        ExecStart =
          let
            executable = "${pkgs.camera-streamer}/bin/camera-streamer";
            parameters = lib.concatStringsSep " " [
              "--camera-path=/base/soc/i2c0mux/i2c@1/imx708@1a"
              "--camera-type=libcamera"
              "--camera-format=YUYV"
              "--camera-width=2304"
              "--camera-height=1296"
              "--camera-fps=30"
              "--camera-nbufs=2"
              "--camera-snapshot.height=1080"
              "--camera-video.height=720"
              "--camera-stream.height=480"
              "--camera-options=AfMode=2"
              "--camera-options=AfRange=2"
              "--http-listen=0.0.0.0"
              "--http-port=8080"
            ];
          in "${executable} ${parameters}";
        DynamicUser = "yes";
        SupplementaryGroups = [ "video" ];
        Restart = "always";
        RestartSec = 10;
        Nice = 10;
        IOSchedulingClass = "idle";
        IOSchedulingPriority = 7;
        CPUWeight = 20;
        AllowedCPUs = "1-2";
        MemoryMax = "250M";
      };
    };
  };

  networking.firewall = {
    allowedTCPPorts = [ 80 8080 ];
    allowedUDPPorts = [ 80 8080 ];
  };

  # Grant the `moonraker` user access to the /run/klipper/api socket.
  users.users.moonraker.extraGroups = [ "klipper" ];

  security.polkit.enable = true;

  services = {
    mainsail.enable = true;

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
