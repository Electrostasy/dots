final: prev:

let
  inherit (prev) lib;

  packages = lib.packagesFromDirectoryRecursive {
    callPackage = lib.callPackageWith (prev // packages);
    directory = ../pkgs;
  };

  recurse = lib.mapAttrs (name: value:
    if lib.hasAttrByPath [ name "overrideScope" ] prev then
      prev.${name}.overrideScope (final': prev': value)
    else if lib.hasAttrByPath [ name "extend" ] prev then
      prev.${name}.extend (final': prev': value)
    else if lib.isAttrs value then
      recurse value
    else
      value);
in
  recurse packages
