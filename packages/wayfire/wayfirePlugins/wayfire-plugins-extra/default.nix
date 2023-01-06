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
  version = "unstable-2022-12-18";

  src = fetchFromGitHub {
    owner = "WayfireWM";
    repo = "wayfire-plugins-extra";
    rev = "ac7b7ed57f66793695f8725939b7df93cd10a27a";
    sha256 = "sha256-ZEsV17A9HxaaWDghSFoziwhEV1P6P+1IfswM3dpXI/M=";
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
