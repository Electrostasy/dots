# Looking Glass B7 has funky fractional scaling, at least on GNOME (usually
# does not work). This [1] commit addresses this issue, but it cannot be
# applied cleanly as a patch without bringing in other patches, since it has
# been so long since a release.
# [1]: https://github.com/gnif/LookingGlass/commit/13b6e042560ea5d63e9f973b2a00f2523b9f0518

final: prev: {
  looking-glass-client = prev.looking-glass-client.overrideAttrs (finalAttrs: prevAttrs: {
    version = "B8-rc1";

    src = prevAttrs.src.override {
      rev = null;
      tag = finalAttrs.version;
      hash = "sha256-ropEJC9+Gg85DS9XRuTb2IRGNNmUcA09Sy/cN6DTvZE=";
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
