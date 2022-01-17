{ inputs, lib, stdenv, meson, ninja, pkg-config, librsvg, libdrm, libexecinfo, libinput, libjpeg, libxkbcommon, wayland, wayland-protocols, mesa, wayfire, wlroots, wf-config }:

with lib;

stdenv.mkDerivation {
  pname = "wayfire-shadows";
  version = "0.1";

  src = inputs.wayfire-shadows;

  nativeBuildInputs = [ meson ninja pkg-config wayland ];

  buildInputs = [ librsvg libdrm libexecinfo libinput libjpeg libxkbcommon wayland wayland-protocols mesa wayfire wlroots wf-config ];

  mesonFlags = [ "--sysconfdir /etc" ];

  PKG_CONFIG_WAYFIRE_METADATADIR = "share/wayfire/metadata";
}
