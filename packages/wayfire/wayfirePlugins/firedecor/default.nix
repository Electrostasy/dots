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
  version = "unstable-2022-03-29";

  src = fetchFromGitHub {
    owner = "AhoyISki";
    repo = "wayfire-firedecor";
    rev = "bb776aca20f627f02b6e2fb0ea7d573eae181166";
    sha256 = "sha256-zhk0ypOuf8hfO2aPSwN2X1HNiPn2b5bj2NP1eJcfNYE=";
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
