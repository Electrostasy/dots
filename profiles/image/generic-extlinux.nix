{ config, pkgs, ... }:

{
  imports = [ ./repart.nix ];

  assertions = [
    {
      assertion = config.boot.loader.generic-extlinux-compatible.enable;
      message = "generic-extlinux image profile can only be used with extlinux";
    }
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
          SizeMinBytes = "1G";
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
