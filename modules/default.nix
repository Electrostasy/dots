{ nixpkgs, ... }:

let
  inherit (nixpkgs) lib;
in

lib.pipe ./. [
  builtins.readDir

  (lib.flip removeAttrs [(baseNameOf __curPos.file)])

  (lib.mapAttrs' (name: _: {
    name = lib.removeSuffix ".nix" name;
    value = ./${name};
  }))

  (modules: modules // { default.imports = builtins.attrValues modules; })
]
