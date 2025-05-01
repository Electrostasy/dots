{ config, pkgs, ... }:

{
  imports = [ ../../profiles/image.nix ];

  nixpkgs.overlays = [
    # If our bootloader EEPROM version from raspberrypi/rpi-eeprom is too new,
    # then we need accordingly new firmware files or else we will not be able
    # to boot.
    # TODO: Remove when it is updated in nixpkgs.
    (final: prev: {
      raspberrypifw = prev.raspberrypifw.overrideAttrs (finalAttrs: oldAttrs: {
        version = "1.20250305";

        src = oldAttrs.src.override {
          rev = null;
          tag = finalAttrs.version;
          hash = "sha256-J2Na7yGKvRDWKC+1gFEQMuaam+4vt+RsV9FjarDgvMs=";
        };
      });
    })
  ];

  image = {
    extension = "raw";

    repart.partitions = {
      "10-esp" = {
        contents = {
          "/".source = pkgs.runCommand "populate-bootloader" { } ''
            ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d $out
          '';

          # Kernel image file that corresponds to the Raspberry Pi 4 Model B
          # (64-bit). In this case, we load U-Boot.
          "/kernel8.img".source = "${pkgs.ubootRaspberryPi4_64bit}/u-boot.bin";

          # Contains many configuration parameters for setting up the Raspberry Pi:
          # https://www.raspberrypi.com/documentation/computers/config_txt.html
          "/config.txt".source = pkgs.writeText "config.txt" ''
            # armstub is the filename on the boot partition from which to load
            # the ARM stub. The default ARM stub is stored in firmware and is
            # selected automatically based on the Raspberry Pi model and various
            # settings.
            armstub=armstub8-gic.bin

            # On the Raspberry Pi 4B, if this value is set to 0 then the interrupts
            # will be routed to the Arm cores using the legacy interrupt controller,
            # rather than via the GIC-400. The default value is 1.
            enable_gic=1

            # enable_uart=1 (in conjunction with console=serial0 in cmdline.txt)
            # requests that the kernel creates a serial console, accessible using
            # GPIOs 14 and 15 (pins 8 and 10 on the 40-pin header).
            enable_uart=1

            # Disable the low voltage warning.
            avoid_warnings=1

            # If upstream_kernel=1 is used, the firmware will prefer upstream
            # Linux names for DTBs (bcm2837-rpi-3-b.dtb instead of bcm2710-rpi-3-b.dtb,
            # for example). If the upstream file isn’t found the firmware will
            # load the downstream variant instead and automatically apply the
            # "upstream" overlay to make some adjustments.
            upstream_kernel=1
          '';

          # The stub is a small piece of ARM code that is run before the kernel.
          # Its job is to set up low-level hardware like the interrupt controller
          # before passing control to the kernel.
          "/armstub8-gic.bin".source = "${pkgs.raspberrypi-armstubs}/armstub8-gic.bin";

          # Binary firmware blob loaded onto the VideoCore GPU in the SoC, which
          # then takes over the boot process.
          "/start4.elf".source = "${pkgs.raspberrypifw}/share/raspberrypi/boot/start4.elf";

          # Linker file found in a matched pair with the start.elf file.
          "/fixup4.dat".source = "${pkgs.raspberrypifw}/share/raspberrypi/boot/fixup4.dat";

          # The base Device Trees are located alongside start.elf in the FAT
          # partition in *.dtb format, and the Pi will not boot without a
          # matching Device Tree.
          "/bcm2711-rpi-4-b.dtb".source = "${config.hardware.deviceTree.package}/broadcom/bcm2711-rpi-4-b.dtb";
        };

        repartConfig = {
          Type = "esp";
          Format = "vfat";
          Label = "BOOT";
          SizeMinBytes = "512M";
        };
      };

      "20-root" = {
        storePaths = [ config.system.build.toplevel ];

        repartConfig = {
          Type = "root";
          Format = "ext4";
          Label = "nixos";
          Minimize = "guess";
        };
      };
    };
  };

  systemd.repart = {
    enable = true;

    partitions."20-root".Type = "root";
  };
}
