{ nixpkgs, ... } @inputs:

let
  inherit (nixpkgs) lib;
in

lib.pipe ./. [
  builtins.readDir

  (lib.flip removeAttrs [(baseNameOf __curPos.file)])

  (lib.mapAttrsToList (name: _: import ./${name} inputs))

  (lib.foldr (lib.recursiveUpdate) { })
]
