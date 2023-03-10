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
  version = "unstable-2023-03-09";

  src = fetchFromGitHub {
    owner = "timgott";
    repo = "wayfire-shadows";
    rev = "dbcd78989631aa712f7b716a8b3a82256f1e2559";
    sha256 = "sha256-ct5SqP/LcDh/Ff72Enf461fB1u0O3LoGLTuLZx8IPOc=";
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
