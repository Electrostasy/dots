inputs:

let
  inherit (inputs.nixpkgs) lib;
in

# Combines the expressions from all the files in this directory containing
# flake checks.

lib.pipe ./. [
  builtins.readDir

  (lib.filterAttrs (name: _:
    name != "default.nix"))

  (lib.mapAttrsToList (name: _:
    import ./${name} inputs))

  (lib.foldr (lib.recursiveUpdate) { })
]
