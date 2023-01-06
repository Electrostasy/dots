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
  version = "unstable-2022-12-21";

  src = fetchFromGitHub {
    owner = "timgott";
    repo = "wayfire-shadows";
    rev = "0dad0f75f5c1b659a9caea5d13717f3064730dcf";
    sha256 = "sha256-+PVWcC+pzGhzA2Z+kPgp9s2f+k73q0pFyZ/dJbmS61I=";
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

    # Can't compile until changes in wayfire-git are caught up with
    broken = true;
  };
}
