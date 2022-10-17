{
  cairo,
  fetchFromGitHub,
  libxkbcommon,
  meson,
  ninja,
  pango,
  pkg-config,
  stdenv,
  wayfire,
  wayland,
  wf-config,
  wlroots,
}:

stdenv.mkDerivation {
  pname = "wayfire-shadows";
  version = "unstable-2022-09-08";

  src = fetchFromGitHub {
    owner = "timgott";
    repo = "wayfire-shadows";
    rev = "8840202b867b04814e22df01b85518b4afe30f11";
    sha256 = "sha256-/G4bRseEhoIt92qLG2UmPThndF5fZxPdQFBA5jlknxs=";
  };

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    wayland
  ];

  buildInputs = [
    cairo
    libxkbcommon
    pango
    wayfire
    wf-config
    wlroots
  ];

  PKG_CONFIG_WAYFIRE_LIBDIR = "lib";
  PKG_CONFIG_WAYFIRE_METADATADIR = "share/wayfire/metadata";
}
