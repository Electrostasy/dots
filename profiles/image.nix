{ config, pkgs, modulesPath, ... }:

{
  imports = [ "${modulesPath}/image/repart.nix" ];

  image.repart.name = "nixos-${config.networking.hostName}-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}";
}
