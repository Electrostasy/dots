{ config, pkgs, lib, modulesPath, ... }:

let
  inherit (pkgs.stdenv.hostPlatform) efiArch;
in

{
  imports = [ "${modulesPath}/image/repart.nix" ];

  assertions = [
    {
      assertion = config.boot.loader.systemd-boot.enable;
      message = "generic-efi image profile currently only supports systemd-boot";
    }
    {
      assertion = !config.boot.loader.generic-extlinux-compatible.enable;
      message = "generic-efi image profile cannot be used with extlinux";
    }
    {
      assertion = config.hardware.deviceTree.enable -> config.hardware.deviceTree.name != null;
      message = "generic-efi image profile requires hardware.deviceTree.name to be set when using hardware.deviceTree.enable";
    }
  ];

  image.repart = {
    name = "nixos-${config.networking.hostName}-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}";

    partitions = {
      "10-esp" = {
        contents = {
          "/EFI/BOOT/BOOT${lib.toUpper efiArch}.EFI".source = "${config.systemd.package}/lib/systemd/boot/efi/systemd-boot${efiArch}.efi";
          "/EFI/systemd/systemd-boot${efiArch}.efi".source = "${config.systemd.package}/lib/systemd/boot/efi/systemd-boot${efiArch}.efi";
          "/EFI/nixos/${config.system.boot.loader.kernelFile}".source = "${config.boot.kernelPackages.kernel}/${config.system.boot.loader.kernelFile}";
          "/EFI/nixos/${config.system.boot.loader.initrdFile}".source = "${config.system.build.initialRamdisk}/${config.system.boot.loader.initrdFile}";

          "/loader/entries/nixos-generation-1.conf".source = pkgs.writeText "nixos-generation-1.conf" ''
            title NixOS
            linux /EFI/nixos/${config.system.boot.loader.kernelFile}
            initrd /EFI/nixos/${config.system.boot.loader.initrdFile}
            ${lib.optionalString config.hardware.deviceTree.enable "devicetree /EFI/nixos/${baseNameOf config.hardware.deviceTree.name}"}
            options init=${config.system.build.toplevel}/init ${toString config.boot.kernelParams}
          '';
        } // lib.optionalAttrs config.hardware.deviceTree.enable {
          "/EFI/nixos/${baseNameOf config.hardware.deviceTree.name}".source = "${config.hardware.deviceTree.package}/${config.hardware.deviceTree.name}";
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
