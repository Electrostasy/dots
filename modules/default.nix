{ nixpkgs, ... }:

let
  inherit (nixpkgs) lib;

  modules = lib.pipe ./. [
    builtins.readDir

    (lib.filterAttrs (name: _: name != "default.nix"))

    (lib.mapAttrs' (name: _: {
      name = lib.removeSuffix ".nix" name;
      value = ./${name};
    }))
  ];
in

{
  default = {
    imports = lib.attrValues modules;
  };
} // modules
