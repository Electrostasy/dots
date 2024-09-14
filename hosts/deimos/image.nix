{ config, pkgs, modulesPath, ... }:

{
  imports = [ "${modulesPath}/image/repart.nix" ];

  image.repart = {
    name = "${config.networking.hostName}-image-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}";

    partitions = {
      "esp" = {
        contents = {
          "/".source = pkgs.runCommand "populate-bootloader" { } ''
            ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d $out
          '';

          "/kernel8.img".source = "${pkgs.ubootRaspberryPi3_64bit}/u-boot.bin";

          "/config.txt".source = pkgs.writeText "config.txt" ''
            arm_64bit=1
            enable_uart=1
            avoid_warnings=1
            upstream_kernel=1
          '';

          "/bootcode.bin".source = "${pkgs.raspberrypifw}/share/raspberrypi/boot/bootcode.bin";
          "/fixup.dat".source = "${pkgs.raspberrypifw}/share/raspberrypi/boot/fixup.dat";
          "/start.elf".source = "${pkgs.raspberrypifw}/share/raspberrypi/boot/start.elf";

          # With `upstream_kernel=1` set in `config.txt`, upstream DTB names may
          # be used.
          "/bcm2837-rpi-zero-2-w.dtb".source = "${config.boot.kernelPackages.kernel}/dtbs/broadcom/bcm2837-rpi-zero-2-w.dtb";
        };

        repartConfig = {
          Type = "esp";
          Format = "vfat";
          Label = "BOOT";
          SizeMinBytes = "512M";
        };
      };

      "root" = {
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

  # Make an image with a hybrid MBR, as the Raspberry Pi 02w does not support
  # booting from GPT directly. Adapted to `sgdisk` from this forum post:
  # https://forums.raspberrypi.com/viewtopic.php?t=320299#p1920410
  system.build.image-hybrid = config.system.build.image.overrideAttrs {
    postFixup = ''
      ${pkgs.gptfdisk}/bin/sgdisk --typecode=1:0c01 --hybrid=1:EE $out/${config.image.repart.imageFile}
    '';
  };

  # Enables expanding the root filesystem on boot.
  systemd.repart = {
    enable = true;

    partitions."10-root".Type = "root";
  };
}
