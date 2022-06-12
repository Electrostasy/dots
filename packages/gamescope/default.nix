{
  fetchFromGitHub,
  glslang,
  lib,
  libcap,
  libinput,
  libliftoff,
  libseat,
  libX11,
  libXcomposite,
  libXext,
  libXi,
  libxkbcommon,
  libXrender,
  libXres,
  libXtst,
  mesa,
  meson,
  ninja,
  pipewire,
  pixman,
  pkgconfig,
  SDL2,
  stb,
  stdenv,
  vulkan-loader,
  wayland,
  wayland-protocols,
  wlroots,
  xcbutilerrors,
  xcbutilwm,
  xwayland,
}:

stdenv.mkDerivation rec {
  pname = "gamescope";
  version = "3.11.31-beta7";

  src = fetchFromGitHub {
    owner = "plagman";
    repo = "gamescope";
    rev = version;
    sha256 = "sha256-SiyZDtxFgRwU5iKhts4NZ3oqF61Mcp9lQzTYV7LmCFI=";
  };

  postUnpack = ''
    mkdir source/subprojects/stb
    cp -r ${stb}/include/stb source/subprojects
    cp source/subprojects/packagefiles/stb/meson.build source/subprojects/stb
    rm -rf source/subprojects/packagefiles source/subprojects/stb.wrap

    rm -rf source/subprojects/libliftoff/*
    cp -r ${libliftoff.src}/* source/subprojects/libliftoff

    rm -rf source/subprojects/wlroots/*
    cp -r ${wlroots.src}/* source/subprojects/wlroots
  '';

  nativeBuildInputs = [
    glslang
    meson
    ninja
    pkgconfig
  ];

  buildInputs = [
    libcap
    libinput
    libseat
    libXcomposite
    libXext
    libXi
    libxkbcommon
    libXrender
    libXres
    libXtst
    mesa
    pipewire
    pixman
    SDL2
    vulkan-loader
    wayland
    wayland-protocols
    xcbutilerrors
    xcbutilwm
    xwayland
  ];

  meta = with lib; {
    description = "SteamOS session compositing window manager";
    homepage = "https://github.com/Plagman/gamescope";
    license = licenses.bsd2;
    maintainers = [ ];
    platforms = platforms.linux;
  };
}
