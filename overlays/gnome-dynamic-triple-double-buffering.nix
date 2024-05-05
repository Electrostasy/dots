final: prev: {
  gnome = prev.gnome.overrideScope (final': prev': {
    mutter = prev'.mutter.overrideAttrs (oldAttrs: {
      patches = (oldAttrs.patches or []) ++ [
        # https://gitlab.gnome.org/GNOME/mutter/-/merge_requests/1441
        (prev.fetchpatch2 {
          name = "mutter-dynamic-triple-double-buffering.patch";
          url = "https://gitlab.gnome.org/GNOME/mutter/-/merge_requests/1441/diffs.patch?diff_id=1105440";
          hash = "sha256-qg8MzbQxaHrpkOxvYgxdrx1libYXTh8+4OBI44lRB58=";
        })
      ];
    });
  });
}
