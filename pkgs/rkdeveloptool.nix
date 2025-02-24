{ rkdeveloptool
, fetchpatch
}:

rkdeveloptool.overrideAttrs (oldAttrs: {
  patches = oldAttrs.patches or [] ++ [
    # https://github.com/rockchip-linux/rkdeveloptool/pull/106
    (fetchpatch {
      name = "rkdeveloptool-change-storage.patch";
      url = "https://github.com/rockchip-linux/rkdeveloptool/commit/554066a0898de0aaf5ea9a5157753dd09ab9c0ef.patch";
      hash = "sha256-BrEHiozN1riENRspQJqL8t7QFK7ecYadtqVgu8VSTds=";
    })
  ];
})
