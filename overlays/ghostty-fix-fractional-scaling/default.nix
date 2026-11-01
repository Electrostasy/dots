final: prev: {
  ghostty = prev.ghostty.overrideAttrs (prevAttrs: {
    patches = prevAttrs.patches or [] ++ [
      # https://github.com/ghostty-org/ghostty/discussions/13911#discussioncomment-18645338
      ./0001-fix-fractional-scaling.diff
    ];
  });
}
