{ config, pkgs, lib, modulesPath, ... }:

{
  imports = [ "${modulesPath}/installer/sd-card/sd-image.nix" ];

  disabledModules = [ "${modulesPath}/profiles/all-hardware.nix" ];

  sdImage = {
    imageBaseName = "${config.networking.hostName}-sd-image";
    compressImage = false;

    populateFirmwareCommands = ''
      cat <<EOF > ./firmware/config.txt
      armstub=armstub8-gic.bin
      enable_gic=1
      enable_uart=1
      avoid_warnings=1
      EOF

      cp ${pkgs.raspberrypi-armstubs}/armstub8-gic.bin ./firmware/armstub8-gic.bin
      cp ${pkgs.ubootRaspberryPi4_64bit}/u-boot.bin ./firmware/kernel8.img
      cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/{fixup4.dat,start4.elf,bcm2711-rpi-4-b.dtb} ./firmware
    '';

    populateRootCommands = ''
      mkdir -p ./files/boot
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
    '';
  };

  # `auto-allocate-uids` breaks rebuilding in a booted up NixOS image, we can
  # disable it via the `nixos-rebuild` flag `--option auto-allocate-uids false`
  # or just override it to `false` in the image media:
  # https://github.com/NixOS/nix/issues/8911
  nix.settings.auto-allocate-uids = lib.mkImageMediaOverride false;
}
