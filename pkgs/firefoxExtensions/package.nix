# Copied with minor alterations from:
# https://git.sr.ht/~rycee/nur-expressions/tree/9cb92b3f92598f77aa8b95b54e5d72ad23745d64/item/pkgs/firefox-addons/default.nix#L5-25

{ stdenv
, fetchurl
, lib
}:

let
  buildFirefoxXpiAddon =
    {
      pname,
      version,
      url,
      sha256,
      addonId,
      meta,
      ...
    }:

    stdenv.mkDerivation {
      inherit pname version meta;

      src = fetchurl { inherit url sha256; };

      preferLocalBuild = true;
      allowSubstitutes = true;

      passthru = { inherit addonId; };

      buildCommand = ''
        dst="$out/share/mozilla/extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}"
        mkdir -p "$dst"
        install -v -m644 "$src" "$dst/${addonId}.xpi"
      '';
    };
in

import ./generated.nix {
  inherit stdenv fetchurl lib buildFirefoxXpiAddon;
}
