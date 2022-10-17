{ fetchFromGitHub,
  libinput,
  librsvg,
  libxkbcommon,
  meson,
  ninja,
  pkg-config,
  stdenv,
  wayfire,
  wayland,
  wf-config,
  wlroots,
  pixman,
  cairo,
  glib,
  gdk-pixbuf,
  boost,
  udev,
  pango
}:

stdenv.mkDerivation {
  pname = "wayfire-firedecor";
  version = "unstable-2022-07-24";

  src = fetchFromGitHub {
    owner = "AhoyISki";
    repo = "Firedecor";
    rev = "3c6777dc64bc2e62ea495a8c99a712dee8c20edb";
    sha256 = "sha256-9GMB9aMyak/D58yw0V4dyzr+cDZ0xmx+a19+Hdn4xHg=";
  };

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    wayland
  ];

  buildInputs = [
    boost
    cairo
    gdk-pixbuf
    glib
    libinput
    librsvg
    libxkbcommon
    pango
    pixman
    udev
    wayfire
    wf-config
    wlroots
  ];

  CPPFLAGS = "-Wno-comment -Wno-cpp";
  PKG_CONFIG_WAYFIRE_LIBDIR = "lib";
  PKG_CONFIG_WAYFIRE_METADATADIR = "share/wayfire/metadata";
}
