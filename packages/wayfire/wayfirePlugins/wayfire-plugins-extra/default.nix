{
  cairo,
  fetchFromGitHub,
  glibmm,
  glm,
  libxkbcommon,
  meson,
  ninja,
  pango,
  pkg-config,
  stdenv,
  wayfire,
  wayland,
  wayland-protocols,
}:

stdenv.mkDerivation {
  pname = "wayfire-plugins-extra";
  version = "unstable-2022-04-23";

  src = fetchFromGitHub {
    owner = "WayfireWM";
    repo = "wayfire-plugins-extra";
    rev = "bcadd22d282709a8ee12ebfe5fd9f4fa17d469d2";
    sha256 = "sha256-e4R5AVVtAFct1pCxSgLHEzV2xA+MCYoxHrZ12OksEkE=";
  };

  dontUseCmakeConfigure = true;

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    wayland
  ];

  buildInputs = [
    cairo
    glibmm
    glm
    libxkbcommon
    pango
    wayfire
    wayland
    wayland-protocols
  ];

  PKG_CONFIG_WAYFIRE_LIBDIR = "lib";
  PKG_CONFIG_WAYFIRE_METADATADIR = "share/wayfire/metadata";
}
