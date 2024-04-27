final: prev: {
  # `ewfmount` depends on `fuse` to mount *.E01 forensic images.
  libewf = prev.libewf.overrideAttrs (oldAttrs: {
    buildInputs = oldAttrs.buildInputs ++ [ prev.fuse ];
  });
}
