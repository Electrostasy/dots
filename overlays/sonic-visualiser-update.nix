# https://github.com/NixOS/nixpkgs/pull/370573

final: prev: {
  sonic-visualiser = (prev.sonic-visualiser.override { librdf_raptor = null; librdf_rasqal = null; }).overrideAttrs (finalAttrs: {
    version = "5.0.1";

    src = prev.fetchzip {
      url = "https://github.com/sonic-visualiser/sonic-visualiser/releases/download/sv_v${finalAttrs.version}/sonic-visualiser-${finalAttrs.version}.tar.gz";
      hash = "sha256-ij436pciCVQK5/8haSDVKjOvypm1zkfw3iYnb+8QX0g=";
    };
  });
}
