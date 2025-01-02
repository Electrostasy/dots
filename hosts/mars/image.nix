{ config, pkgs, lib, modulesPath, ... }:

{
  imports = [
    # We cannot use the `image.repart` module here, because systemd-repart does
    # not support setting the GPT table length or adding holes in the GPT
    # table. RK3588 expects u-boot to be present at offset 0x00008000, but the
    # best we can do with systemd-repart is offset 0x00100000.
    "${modulesPath}/installer/sd-card/sd-image.nix"
    "${modulesPath}/image/file-options.nix"
  ];

  hardware.enableAllHardware = lib.mkImageMediaOverride false;

  image = {
    baseName = "nixos-${config.networking.hostName}-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}";
    extension = "img";
  };

  system.build.image = config.system.build.sdImage;

  sdImage = {
    imageBaseName = config.image.baseName;
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
