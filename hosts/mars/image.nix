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
}
