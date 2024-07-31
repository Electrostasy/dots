final: prev: {
  # Contains various fixes since 2.0.0.
  unl0kr = prev.unl0kr.overrideAttrs (finalAttrs: oldAttrs: {
    version = "3.2.0";

    src = oldAttrs.src.override {
      owner = "postmarketOS";
      repo = "buffybox";
      rev = finalAttrs.version;
      hash = "sha256-nZX7mSY9IBIhVNmOD6mXI1IF2TgyKLc00a8ADAvVLB0=";
    };

    sourceRoot = "${finalAttrs.src.name}/unl0kr";
  });
}
