{
  cairo,
  fetchFromGitHub,
  fetchpatch,
  glib,
  glibmm,
  libxcb,
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
  pname = "wayfire-dbus_interface";
  version = "unstable-2021-05-14";

  src = fetchFromGitHub {
    owner = "damianatorrpm";
    repo = "wayfire-plugin_dbus_interface";
    rev = "c7cc8e11e7f8fa2b725eb8feab6d05a8242709e7";
    sha256 = "sha256-2pOMvRLRF1CZlc+0r+JWt+8nqUdtFt68oiw6Fs0agcg=";
  };

  patches = [
    (fetchpatch {
      url = "https://github.com/damianatorrpm/wayfire-plugin_dbus_interface/pull/48.patch";
      sha256 = "sha256-kB+JxIG0f7B8bu8o736f63FavRz+KwCTY3Lf9+PHJQc=";
    })
  ];

  dontUseCmakeConfigure = true;

  postUnpack = ''
    patchShebangs source/compile-schemas.sh
  '';

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    wayland
  ];

  buildInputs = [
    cairo
    glib
    glibmm
    libxcb
    libxkbcommon
    pango
    wayfire
    wf-config
    wlroots
  ];

  CPPFLAGS = "-Wno-unused-function -Wno-sign-compare -Wno-unused-variable";
  PKG_CONFIG_WAYFIRE_LIBDIR = "lib";
  PKG_CONFIG_WAYFIRE_METADATADIR = "share/wayfire/metadata";
}
