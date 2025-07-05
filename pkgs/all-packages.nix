{ nixpkgs, ... }:

let
  inherit (nixpkgs) lib;
in

# Combines the expressions from all the files in this directory containing
# Nix packages.

lib.genAttrs
  [ "aarch64-darwin" "aarch64-linux" "x86_64-darwin" "x86_64-linux" ]
  (system:
    let
      packages =
        lib.removeAttrs
          (lib.packagesFromDirectoryRecursive {
            callPackage = lib.callPackageWith (nixpkgs.legacyPackages.${system} // packages);
            directory = ./.;
          })
        [ "all-packages" ];
    in
      packages)
