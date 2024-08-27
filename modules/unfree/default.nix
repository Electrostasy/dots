# This module allows merging lists of unfree packages declared in different
# modules, which the standard nixpkgs.config.allowUnfreePredicate does not
# support. This is copied with minor modifications from this post:
# https://github.com/NixOS/nixpkgs/issues/197325#issuecomment-1579420085

{ config, lib, ... }:

{
  options = {
    nixpkgs.allowUnfreePackages = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
      example = [ "steam" "steam-original" ];
    };
  };

  config = {
    nixpkgs.config.allowUnfreePredicate = pkg:
      builtins.elem (lib.getName pkg) config.nixpkgs.allowUnfreePackages;
  };
}
