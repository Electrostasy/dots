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
, meson_0_60
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
    rev = "7c94fc3437a1c56cc2971091421cd6837f39c58a";
    sha256 = "sha256-+wRVIFBlIsFOjljOWXhYvs9FGsK70NyNKulB2d/iQ0s=";
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
  wayland_1_20_0 = fetchurl {
    url = "https://wayland.freedesktop.org/releases/wayland-1.20.0.tar.xz";
    sha256 = "09c7rpbwavjg4y16mrfa57gk5ix6rnzpvlnv1wp7fnbh9hak985q";
  };
in

stdenv.mkDerivation {
  pname = "gamescope";
  version = "3.10.3";

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

  # preConfigure = ''
  #   substituteInPlace meson.build --replace \
  #   "'examples=false'" \
  #   "'examples=false', 'logind-provider=systemd', 'libseat=disabled'"
  # '';

  nativeBuildInputs = [
    glslang
    makeWrapper
    meson_0_60
    ninja
    pkgconfig
  ];

  postInstall = ''
    wrapProgram $out/bin/gamescope --prefix PATH:"${lib.makeBinPath [ xwayland ]}"
  '';

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
    (wayland.overrideAttrs(_: { src = wayland_1_20_0; version = "1.20.0"; patches = []; }))
    wayland-protocols
    xcbutilerrors
    xcbutilrenderutil
    xcbutilwm
    xwayland
  ];
}

