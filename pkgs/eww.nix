{ eww, fetchFromGitHub, ... }:

(eww.overrideAttrs (old: rec {
  src = fetchFromGitHub {
    owner = "elkowar";
    repo = "eww";
    rev = "106106ade31e7cc669f2ae53f24191cd0a683c39";
    sha256 = "sha256-VntDl7JaIfvn3pd+2uDocnXFRkPnQQbRkYDn4XWeC5o=";
  };
  cargoDeps = old.cargoDeps.overrideAttrs (_: {
    inherit src;
    outputHash = "sha256-+OJ1BC/+iKkoCK2/+xA26fG2XtcgKJMv4UHmhc9Yv9k=";
  });
})).override { withWayland = true; }
