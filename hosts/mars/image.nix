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
        contents."/".source = pkgs.runCommand "populate-bootloader" { } ''
          ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d $out
        '';

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
