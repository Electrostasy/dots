# Looking Glass B7 has funky fractional scaling, at least on GNOME (usually
# does not work). This [1] commit addresses this issue, but it cannot be
# applied cleanly as a patch without bringing in other patches, since it has
# been so long since a release.
# [1]: https://github.com/gnif/LookingGlass/commit/13b6e042560ea5d63e9f973b2a00f2523b9f0518

final: prev: {
  looking-glass-client = prev.looking-glass-client.overrideAttrs (prevAttrs: {
    version = "B7-unstable-2026-09-01";

    src = prevAttrs.src.override {
      rev = "236efcb155f952f5d7d9fcd5891a3060ad254e68";
      hash = "sha256-NAfV4Z0RZp2IGBzVAFysm53aGMEReT03RIN+45TveUU=";
    };

    buildInputs = prevAttrs.buildInputs ++ [
      prev.fuse3
      prev.libunwind
      prev.elfutils # `libdw`.
    ];

    patches = [
      # Upstream nixpkgs patch is incompatible, it must be overridden.
      ./nanosvg-unvendor.diff
    ];
  });
}
