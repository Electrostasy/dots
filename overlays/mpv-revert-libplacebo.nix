final: prev: {
  mpv-unwrapped = prev.mpv-unwrapped.override {
    libplacebo = prev.libplacebo.overrideAttrs (prevAttrs: {
      patches = prevAttrs.patches or [] ++ [
        # Vulkan backend on MPV is broken because of this:
        # https://github.com/haasn/libplacebo/issues/333
        (prev.fetchpatch {
          name = "revert_vulkan_gpu_set_correct_pl_spirv_version_for_Vulkan_1_4.patch";
          url = "https://github.com/haasn/libplacebo/commit/4c6d99edee23284f93b07f0f045cd660327465eb.patch";
          revert = true;
          hash = "sha256-zoCgd9POlhFTEOzQmSHFZmJXgO8Zg/f9LtSTSQq5nUA=";
        })
      ];
    });
  };
}
