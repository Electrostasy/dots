final: prev:

/*
  Generate an overlay from `pkgs` by handling the `callPackage` behaviour
  ourselves, making exceptions for namespaced package sets. We cannot reuse
  the definitions from `self.legacyPackages.${prev.system}`, as that would
  evaluate nixpkgs twice here (prev.system does not exist then).
*/

let
  lib = prev.lib;

  pkgs = lib.packagesFromDirectoryRecursive {
    callPackage = path: overrides: path;
    directory = ../pkgs;
  };
in
  lib.mapAttrs
    (name: value:
      if lib.isAttrs value then
        if lib.hasAttrByPath [ name "overrideScope" ] prev then
          # Namespaced package sets created with `lib.makeScope pkgs.newScope`.
          prev.${name}.overrideScope (final': prev':
            lib.mapAttrs (name': value': final'.callPackage value' { }) value)
        else if lib.hasAttrByPath [ name "extend" ] prev then
          # Namespaced package sets created with `lib.makeExtensible`.
          prev.${name}.extend (final': prev':
            lib.mapAttrs (name': value': final.callPackage value' { }) value)
        else
          # Namespaced package sets in regular attrsets.
          prev.${name} // value
      else
        final.callPackage value { })
    pkgs
