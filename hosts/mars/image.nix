{ config, lib, modulesPath, ... }:

{
  imports = [ "${modulesPath}/installer/sd-card/sd-image.nix" ];

  disabledModules = [ "${modulesPath}/profiles/all-hardware.nix" ];

  sdImage = {
    imageBaseName = "${config.networking.hostName}-sd-image";
    compressImage = false;
    storePaths = [ config.system.build.uboot ];

    firmwarePartitionOffset = 32;
    populateFirmwareCommands = "";

    populateRootCommands = ''
      mkdir -p ./files/boot
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
    '';

    postBuildCommands = ''
      dd if=${config.system.build.uboot}/idbloader.img of=$img seek=64 conv=notrunc
      dd if=${config.system.build.uboot}/u-boot.itb of=$img seek=16384 conv=notrunc
    '';
  };

  # `auto-allocate-uids` breaks rebuilding in a booted up NixOS image, we can
  # disable it via the `nixos-rebuild` flag `--option auto-allocate-uids false`
  # or just override it to `false` in the image media:
  # https://github.com/NixOS/nix/issues/8911
  nix.settings.auto-allocate-uids = lib.mkImageMediaOverride false;

  # sdImage module does not enforce filesystems in installation media, so
  # we do it ourselves here.
  fileSystems = lib.mkImageMediaOverride {
    "/boot/firmware" = {
      device = "/dev/disk/by-label/${config.sdImage.firmwarePartitionName}";
      fsType = "vfat";
      options = [ "nofail" "noauto" ];
    };

    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };
  };
}
