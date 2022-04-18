{ eww-wayland, fetchFromGitHub, fetchpatch, ... }:

eww-wayland.overrideAttrs (old: rec {
  src = fetchFromGitHub {
    owner = "elkowar";
    repo = "eww";
    rev = "106106ade31e7cc669f2ae53f24191cd0a683c39";
    sha256 = "sha256-VntDl7JaIfvn3pd+2uDocnXFRkPnQQbRkYDn4XWeC5o=";
  };
  patches = [
    # Loop widget
    (fetchpatch {
      url = "https://github.com/elkowar/eww/pull/350.patch";
      sha256 = "sha256-WuTdmYSOCpGGmsQ2vGUiMLVmPxWaHIzSTcUHNzTysug=";
    })
    # Scroll widget
    (fetchpatch {
      url = "https://github.com/elkowar/eww/pull/406.patch";
      sha256 = "sha256-Iq5BOvkw4Z2ufQsPXpOPFzwDlmqMpo/3/3plvVYJoEk=";
    })
  ];
  cargoDeps = old.cargoDeps.overrideAttrs (_: {
    inherit src;
    outputHash = "sha256-+OJ1BC/+iKkoCK2/+xA26fG2XtcgKJMv4UHmhc9Yv9k=";
  });
})
