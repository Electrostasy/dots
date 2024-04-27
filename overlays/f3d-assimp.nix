final: prev: {
  # Add support for FBX, OFF, DAE, DXF, X, 3MF files.
  f3d = prev.f3d.overrideAttrs (oldAttrs: {
    buildInputs = oldAttrs.buildInputs ++ [ prev.assimp ];

    cmakeFlags = (oldAttrs.cmakeFlags or []) ++ [
      "-DF3D_PLUGIN_BUILD_ASSIMP=ON"
    ];
  });
}
