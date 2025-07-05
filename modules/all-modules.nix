{ nixpkgs, ... }:

let
  inherit (nixpkgs) lib;
in

# Combines the expressions from all the files in this directory containing
# NixOS modules.

lib.pipe ./. [
  builtins.readDir

  (lib.filterAttrs (name: _: name != "all-modules.nix"))

  (lib.mapAttrs' (name: _: {
    name = lib.removeSuffix ".nix" name;
    value = ./. + "/${name}";
  }))
]
