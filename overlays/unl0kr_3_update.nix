final: prev: {
  # Contains various fixes since 2.0.0.
  unl0kr = prev.unl0kr.overrideAttrs (finalAttrs: oldAttrs: {
    version = "3.0.0";
    src = oldAttrs.src.override {
      owner = "postmarketOS";
      repo = "buffybox";
      rev = finalAttrs.version;
      hash = "sha256-xmyh5F6sqD1sOPdocWJtucj4Y8yqbaHfF+a/XOcMk74=";
    };
    sourceRoot = "${finalAttrs.src.name}/unl0kr";
  });
}
