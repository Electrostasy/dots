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
  pname = "wayfire-firedecor";
  version = "unstable-2022-03-29";

  src = fetchFromGitHub {
    owner = "timgott";
    repo = "wayfire-shadows";
    rev = "b8b170f2af4cb281e8adc95c585df617816c65cc";
    sha256 = "sha256-Fz7cUPG0ldFjcMKN0pdhnxWJF4P/0mKTgncCDnLPoqM=";
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
