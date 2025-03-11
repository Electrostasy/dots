{ config, pkgs, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/image/repart.nix"
    "${modulesPath}/image/file-options.nix"
  ];

  image = {
    baseName = "nixos-${config.networking.hostName}-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}";
    extension = "raw";
  };

  image.repart = {
    name = config.image.baseName;

    partitions = {
      "10-esp" = {
        contents = {
          "/".source = pkgs.runCommand "populate-bootloader" { } ''
            ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d $out
          '';

          # Kernel image file that corresponds to the Raspberry Pi Compute
          # Module 4 (64-bit). In this case, we load U-Boot.
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

            # If we try to access the dwc or XHCI when the firmware hasn't initialized
            # it, the system will freeze. This signals to the firmware to enable the
            # XHCI controller.
            otg_mode=1
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
          "/bcm2711-rpi-cm4-io.dtb".source = "${config.hardware.deviceTree.package}/broadcom/bcm2711-rpi-cm4-io.dtb";
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

          MakeDirectories = "/var/lib/sops-nix";
        };
      };
    };
  };

  systemd.repart = {
    enable = true; # expand the root filesystem on boot.

    partitions."20-root".Type = "root";
  };
}
