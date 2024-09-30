final: prev: {
  adw-gtk3 = prev.adw-gtk3.overrideAttrs (finalAttrs: oldAttrs: {
    version = "5.3";

    src = oldAttrs.src.override {
      rev = "v${finalAttrs.version}";
      sha256 = "sha256-DpJLX9PJX1Q8dDOx7YOXQzgNECsKp5uGiCVTX6iSlbI=";
    };
  });
}
