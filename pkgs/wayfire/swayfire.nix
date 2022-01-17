{ inputs, lib, ... }:

stdenv.mkDerivation {
  pname = "swayfire";
  version = "0.1";

  src = inputs.swayfire;

  nativeBuildInputs = [ meson ninja pkg-config wayland ];

  buildInputs = [ wayfire wf-config wlroots cairo pixman udev mesa glm libxkbcommon libinput libjpeg ];

  mesonFlags = [ "--sysconfdir /etc" ];

  PKG_CONFIG_WAYFIRE_METADATADIR = "share/wayfire/metadata";
}
