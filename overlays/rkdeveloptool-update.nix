final: prev: {
  rkdeveloptool = prev.rkdeveloptool.overrideAttrs (oldAttrs: {
    version = "unstable-2025-03-07";

    src = oldAttrs.src.override {
      rev = "304f073752fd25c854e1bcf05d8e7f925b1f4e14";
      sha256 = "sha256-GcSxkraJrDCz5ADO0XJk4xRrYTk0V5dAAim+D7ZiMJQ=";
    };
  });
}
