{ cairo,
  cmake,
  doctest,
  fetchFromGitHub,
  glslang,
  libdrm,
  libevdev,
  libexecinfo,
  libinput,
  libjpeg,
  libxcb,
  libxkbcommon,
  libxml2,
  mesa,
  meson,
  ninja,
  pango,
  pkg-config,
  seatd,
  stdenv,
  vulkan-headers,
  vulkan-loader,
  wayland,
  wayland-protocols,
  wf-config,
  wlroots,
  xcbproto,
  xcbutil,
  xcbutilerrors,
  xcbutilrenderutil,
  xcbutilwm,
  xwayland
}:

stdenv.mkDerivation {
  pname = "wayfire";
  version = "0.8.0";

  src = fetchFromGitHub {
    fetchSubmodules = true;
    owner = "WayfireWM";
    repo = "wayfire";
    rev = "9458f58959512222f3f154b40b0a48584033ca24";
    sha256 = "sha256-qSBK5kkSykAXNSYA/CpPu2EbA3qHm09KnvcbPGsnrnM=";
  };

  nativeBuildInputs = [
    cmake
    meson
    ninja
    pkg-config
    wayland
  ];

  buildInputs = [
    cairo
    doctest
    glslang
    libdrm
    libevdev
    libexecinfo
    libinput
    libjpeg
    libxcb
    libxkbcommon
    libxml2
    mesa
    pango
    seatd
    vulkan-headers
    vulkan-loader
    wayland
    wayland-protocols
    wf-config
    wlroots
    xcbproto
    xcbutil
    xcbutilerrors
    xcbutilrenderutil
    xcbutilwm
    xwayland
  ];

  # CMake is just used for finding doctest.
  dontUseCmakeConfigure = true;

  mesonFlags = [
    "--sysconfdir" "/etc"
    # Without these meson throws errors about wfconfig submodule not overriding the variable,
    # and missing link arguments -lc++fs, -lc++experimental
    "-Duse_system_wlroots=disabled"
    "-Duse_system_wfconfig=disabled"
  ];
}
