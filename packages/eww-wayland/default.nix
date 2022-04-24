{ eww-wayland, fetchFromGitHub, fetchpatch, ... }:

eww-wayland.overrideAttrs (old: rec {
  src = fetchFromGitHub {
    owner = "elkowar";
    repo = "eww";
    rev = "6b7fa5d55ccd560a3c95b93caa2e945662953db8";
    sha256 = "sha256-1pO7DMxCWU0+yHGtPVD3iaRfOKabP8RXvTsdC+sYSUk=";
  };
  cargoDeps = old.cargoDeps.overrideAttrs (_: {
    inherit src;
    outputHash = "sha256-IqgZiqVKE7Jpsseou8R2LE80Zm9z1qXgkmSgRaCeGRs=";
  });
})
