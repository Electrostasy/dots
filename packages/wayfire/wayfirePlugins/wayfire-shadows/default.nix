{
  stdenv,
  fetchFromGitHub,
  meson,
  ninja,
  pkg-config,

  wayfire,
  cairo,
  pango,
  wayland,
  libxkbcommon,
  wlroots_0_16,
  wf-config,
  
  lib,
}:

stdenv.mkDerivation {
  pname = "wayfire-shadows";
  version = "unstable-2022-11-21";

  src = fetchFromGitHub {
    owner = "timgott";
    repo = "wayfire-shadows";
    rev = "32eeb5f8b772c0cd123b6688bcbbeebc9c99c1c9";
    sha256 = "sha256-IvmbfZK4Z1HOIxGiFyjK1OCXy1fkdwA0L7jfrJtgQWk=";
  };

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
  ];

  buildInputs = [
    wayfire
    cairo
    pango
    wayland
    libxkbcommon
    wlroots_0_16
    wf-config
  ];

  PKG_CONFIG_WAYFIRE_LIBDIR = "lib";
  PKG_CONFIG_WAYFIRE_METADATADIR = "share/wayfire/metadata";

  meta = with lib; {
    website = "https://github.com/timgott/wayfire-shadows";
    description = "Wayfire plugin that adds window shadows";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
