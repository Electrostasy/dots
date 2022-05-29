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
    rev = "3.11.31-beta6";
    sha256 = "sha256-VKhuVNJIUJYQYtKYnLi8Nrn30Q09xfsZD0ev4Zk4SIM=";
  };
  libliftoff_2_0_0 = fetchFromGitLab {
    domain = "gitlab.freedesktop.org";
    owner = "emersion";
    repo = "libliftoff";
    rev = "378ccb4f84a2473fe73dbdc56fe35a0d2ee661cc";
    sha256 = "sha256-mNgcZyQl78f0ZnztKyp5htw+97MTcZqE1Zm/8OapXfs=";
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
  version = "3.11.31-beta6";

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

