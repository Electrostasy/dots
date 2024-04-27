final: prev: {
  # Add support for STEP, IGES files.
  f3d = prev.f3d.overrideAttrs (oldAttrs: {
    buildInputs = oldAttrs.buildInputs ++ (with prev; [
      opencascade-occt
      fontconfig
    ]);

    cmakeFlags = (oldAttrs.cmakeFlags or []) ++ [
      "-DF3D_PLUGIN_BUILD_OCCT=ON"
    ];
  });
}
