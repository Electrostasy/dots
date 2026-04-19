{ config, pkgs, lib, modulesPath, ... }:

{
  imports = [ "${modulesPath}/image/repart.nix" ];

  assertions = [
    {
      assertion = config.boot.loader.generic-extlinux-compatible.enable;
      message = "generic-extlinux image profile can only be used with extlinux";
    }
  ];

  image.repart = {
    name = "nixos-${config.networking.hostName}-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}";

    partitions = {
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

        # Register the contents of the Nix store in the Nix database, based on the
        # work in https://github.com/NixOS/nixpkgs/pull/351699.
        contents."/nix/var/nix".source = lib.mkIf config.nix.enable (
          pkgs.runCommand "nix-state" { nativeBuildInputs = [ pkgs.buildPackages.nix ]; } ''
            mkdir -p $out/profiles
            ln -s ${config.system.build.toplevel} $out/profiles/system-1-link
            ln -s /nix/var/nix/profiles/system-1-link $out/profiles/system

            export NIX_STATE_DIR=$out
            nix-store --load-db < ${pkgs.closureInfo { rootPaths = [ config.system.build.toplevel ]; }}/registration
          ''
        );

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
