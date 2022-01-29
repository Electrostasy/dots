{ SDL2
, fetchFromGitHub
, fetchFromGitLab
, fetchurl
, glslang
, lib
, libX11
, libXcomposite
, libXdamage
, libXext
, libXi
, libXrender
, libXres
, libXtst
, libXxf86vm
, libcap
, libdrm
, libinput
, libliftoff
, libseat
, libuuid
, libxkbcommon
, makeWrapper
, mesa
, meson
, ninja
, pipewire
, pixman
, pkgconfig
, stb
, stdenv
, vulkan-loader
, wayland
, wayland-protocols
, xcbutilerrors
, xcbutilrenderutil
, xcbutilwm
, xwayland
}:

let
  gamescope-src = fetchFromGitHub {
    owner = "plagman";
    repo = "gamescope";
    rev = "8f1fbe7ce0ae705f500b770dad8b9c2bc17f5d2d";
    sha256 = "sha256-KKkHBLA88g84txX6joPiq5sZzbdjKtmVHCEwYQSIOk4=";
  };
  libliftoff_2_0_0 = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "emersion";
    repo = "libliftoff";
    rev = "2e1dd93b60224e77f6a49ad8fb36d184e3a9a3bc";
    sha256 = "sha256-b8Pgr3SgLBenoYgiKbEIH9n150C2cKTwDig/5OEp/k8=";
  };
  wlroots_0_15_0 = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "wlroots";
    repo = "wlroots";
    rev = "9f41627aa10a94d9427bc315fa3d363a61b94d7c";
    sha256 = "sha256-NhCbDsmk2Vp94qMdssGQqzrfrJZ99Dr86zeYfTnQv3E=";
  };
in

stdenv.mkDerivation {
  pname = "gamescope";
  version = "3.10.8";

  src = gamescope-src;

  postUnpack = ''
    pushd source

    mkdir subprojects/stb
    cp -r ${stb}/include/stb subprojects
    cp subprojects/packagefiles/stb/meson.build subprojects/stb
    rm -rf subprojects/packagefiles subprojects/stb.wrap

    rm -rf subprojects/libliftoff/*
    cp -r ${libliftoff_2_0_0}/* subprojects/libliftoff

    rm -rf subprojects/wlroots/*
    cp -r ${wlroots_0_15_0}/* subprojects/wlroots

    popd
  '';

  nativeBuildInputs = [
    glslang
    makeWrapper
    meson
    ninja
    pkgconfig
  ];

  buildInputs = [
    SDL2
    libX11
    libXcomposite
    libXdamage
    libXext
    libXi
    libXrender
    libXres
    libXtst
    libXxf86vm
    libcap
    libdrm
    libinput
    libliftoff
    libseat
    libuuid
    libxkbcommon
    mesa
    pipewire
    pixman
    vulkan-loader
    wayland
    wayland-protocols
    xcbutilerrors
    xcbutilrenderutil
    xcbutilwm
    xwayland
  ];
}

