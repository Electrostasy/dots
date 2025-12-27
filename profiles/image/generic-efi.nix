{ config, pkgs, lib, ... }:

let
  inherit (pkgs.stdenv.hostPlatform) efiArch;
in

{
  imports = [ ./repart.nix ];

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

  image = {
    extension = "raw";

    repart.partitions = {
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
            ${lib.optionalString config.hardware.deviceTree.enable "devicetree /EFI/nixos/${builtins.baseNameOf config.hardware.deviceTree.name}"}
            options init=${config.system.build.toplevel}/init ${builtins.toString config.boot.kernelParams}
          '';
        } // lib.optionalAttrs config.hardware.deviceTree.enable {
          "/EFI/nixos/${builtins.baseNameOf config.hardware.deviceTree.name}".source = "${config.hardware.deviceTree.package}/${config.hardware.deviceTree.name}";
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
