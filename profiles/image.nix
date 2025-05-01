{ config, pkgs, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/image/repart.nix"
    "${modulesPath}/image/file-options.nix"
  ];

  image = {
    baseName = "nixos-${config.networking.hostName}-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}";

    repart.name = config.image.baseName;
  };
}
