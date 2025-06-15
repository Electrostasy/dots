{ config, pkgs, ... }:

{
  imports = [
    ../../profiles/image/repart.nix
    ../../profiles/image/expand-root.nix
  ];

  image = {
    extension = "raw";

    repart.partitions = {
      "10-esp" = {
        contents = {
          "/".source = pkgs.runCommand "populate-bootloader" { } ''
            ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d $out
          '';

          # Kernel image file that corresponds to the Raspberry Pi Zero 2 W model
          # (64-bit). In this case, we load U-Boot.
          "/kernel8.img".source = "${pkgs.ubootRaspberryPi3_64bit}/u-boot.bin";

          # Contains many configuration parameters for setting up the Raspberry Pi:
          # https://www.raspberrypi.com/documentation/computers/config_txt.html
          "/config.txt".source = pkgs.writeText "config.txt" ''
            # If set to 1, the kernel will be started in 64-bit mode. In 64-bit
            # mode, the firmware will choose an appropriate kernel (e.g. kernel8.img),
            # unless there is an explicit kernel option defined, in which case
            # that is used instead. Defaults to 1 on Pi 4s (Pi 4B, Pi 400, CM4
            # and CM4S), and 0 on all other platforms.
            arm_64bit=1

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

          # The bootloader, loaded by the SoC on boot. It performs some very
          # basic setup, and then loads one of the start*.elf files.
          "/bootcode.bin".source = "${pkgs.raspberrypifw}/share/raspberrypi/boot/bootcode.bin";

          # Binary firmware blob loaded onto the VideoCore GPU in the SoC, which
          # then takes over the boot process.
          "/start.elf".source = "${pkgs.raspberrypifw}/share/raspberrypi/boot/start.elf";

          # Linker file found in a matched pair with the start.elf file.
          "/fixup.dat".source = "${pkgs.raspberrypifw}/share/raspberrypi/boot/fixup.dat";

          # The base Device Trees are located alongside start.elf in the FAT
          # partition in *.dtb format, and the Pi will not boot without a
          # matching Device Tree.
          "/bcm2837-rpi-zero-2-w.dtb".source = "${config.hardware.deviceTree.package}/broadcom/bcm2837-rpi-zero-2-w.dtb";
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
}
