{ config, pkgs, lib, ... }:

let
  inherit (pkgs.stdenv.hostPlatform) efiArch;
  inherit (pkgs.stdenv) isAarch64;
in

{
  imports = [ ./repart.nix ];

  image = {
    extension = "raw";

    repart.partitions = {
      "10-esp" = {
        contents = {
          "/EFI/BOOT/BOOT${lib.toUpper efiArch}.EFI".source = "${config.systemd.package}/lib/systemd/boot/efi/systemd-boot${efiArch}.efi";
          "/EFI/systemd/systemd-boot${efiArch}.efi".source = "${config.systemd.package}/lib/systemd/boot/efi/systemd-boot${efiArch}.efi";
          "/EFI/nixos/${config.system.boot.loader.kernelFile}".source = "${config.boot.kernelPackages.kernel}/${config.system.boot.loader.kernelFile}";
          "/EFI/nixos/${config.system.boot.loader.initrdFile}".source = "${config.system.build.initialRamdisk}/${config.system.boot.loader.initrdFile}";
          "/EFI/nixos/${builtins.baseNameOf config.hardware.deviceTree.name}".source =
            lib.mkIf
              isAarch64
              "${config.hardware.deviceTree.package}/${config.hardware.deviceTree.name}";

          "/loader/entries/nixos-generation-1.conf".source = pkgs.writeText "nixos-generation-1.conf" ''
            title NixOS
            linux /EFI/nixos/${config.system.boot.loader.kernelFile}
            initrd /EFI/nixos/${config.system.boot.loader.initrdFile}
            ${lib.optionalString isAarch64 "devicetree /EFI/nixos/${builtins.baseNameOf config.hardware.deviceTree.name}"}
            options init=${config.system.build.toplevel}/init ${builtins.toString config.boot.kernelParams}
          '';
        };

        repartConfig = {
          Type = "esp";
          Format = "vfat";
          Label = "BOOT";
          SizeMinBytes = "1G";
        };
      };

      "20-root" = {
        storePaths = [ config.system.build.toplevel ];

        # Register the contents of the Nix store in the Nix database.
        contents."/nix/var/nix".source = pkgs.runCommand "nix-state" { nativeBuildInputs = [ pkgs.buildPackages.nix ]; } ''
          mkdir -p $out/profiles
          ln -s ${config.system.build.toplevel} $out/profiles/system-1-link
          ln -s /nix/var/nix/profiles/system-1-link $out/profiles/system

          export NIX_STATE_DIR=$out
          nix-store --load-db < ${pkgs.closureInfo { rootPaths = [ config.system.build.toplevel ]; }}/registration
        '';

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
