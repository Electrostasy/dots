{
  stdenv,
  fetchFromGitHub,
  wf-config,
  cmake,
  doctest,
  meson,
  ninja,
  pkg-config,

  wayland,
  wayland-protocols,
  cairo,
  pango,
  libdrm,
  libGL,
  glm,
  libinput,
  pixman,
  libxkbcommon,
  wlroots_0_16,

  xorg,

  lib,

  enableXWayland ? true,
  xwayland,

  enableImageIO ? true,
  libpng,
  libjpeg,

  enableDebugIPC ? false,
  libevdev,
  nlohmann_json,
}:

let
  wf-config-unstable = wf-config.overrideAttrs (_: {
    version = "0.8.0";
    src = fetchFromGitHub {
      owner = "WayfireWM";
      repo = "wf-config";
      rev = "578b0bf3c81ef8f94e5e9b4f427720846bc7a5c5";
      sha256 = "sha256-v3QjYEpaxZNnFEQ9wPvds/lmLJwo8kUD07GENI7mlJk=";
    };
  });
  wf-utils-unstable = fetchFromGitHub {
    owner = "WayfireWM";
    repo = "wf-utils";
    rev = "25ed62f35c0b7810beee2009c6a419847f8f89fe";
    sha256 = "sha256-GBmEoqUbqeAbyllAeNILh0OQWHb6oyavc5hjkbzSfJY=";
  };
  wf-touch-unstable = fetchFromGitHub {
    owner = "WayfireWM";
    repo = "wf-touch";
    rev = "8974eb0f6a65464b63dd03b842795cb441fb6403";
    sha256 = "sha256-MjsYeKWL16vMKETtKM5xWXszlYUOEk3ghwYI85Lv4SE=";
  };
in

stdenv.mkDerivation {
  pname = "wayfire";
  version = "unstable-20230421";

  src = fetchFromGitHub {
    owner = "WayfireWM";
    repo = "wayfire";
    rev = "076dc76f179a5bbb67095a165b29d8d7a5a1dc27";
    sha256 = "sha256-oXYuQ/aM8+zBDeEmVNWPkqL9UxGRrcu4tIxs8OsqCVg=";
  };

  patches = [
    # https://github.com/WayfireWM/wayfire/issues/1695
    # Prevents crashing when dragging windows between outputs, but not ideal
    # solution.
    ./window-drag-crash.patch
  ];

  postUnpack = ''
    # Complains about there not being a meson.build file in the submodules otherwise.
    rm -rf ./source/subprojects/{wf-utils,wf-touch}
    ln -s ${wf-utils-unstable}/ ./source/subprojects/wf-utils
    ln -s ${wf-touch-unstable}/ ./source/subprojects/wf-touch
  '';

  dontUseCmakeConfigure = true;
  nativeBuildInputs = [
    cmake
    doctest
    meson
    ninja
    pkg-config
  ];

  buildInputs = [
    # wayfire
    wayland
    wayland-protocols
    cairo
    pango
    libdrm
    libGL
    glm
    libinput
    pixman
    libxkbcommon
    wlroots_0_16
    wf-config-unstable

    # wf-touch
    xorg.xcbutilwm
  ]
  ++ lib.optional enableXWayland xwayland
  ++ lib.optionals enableImageIO [ libpng libjpeg ]
  ++ lib.optionals enableDebugIPC [ libevdev nlohmann_json ];

  mesonFlags = []
    ++ lib.optional (!enableXWayland) "-Dxwayland=disabled"
    ++ lib.optional (!enableDebugIPC) "-Ddebug_ipc=false";

  meta = with lib; {
    website = "https://wayfire.org";
    description = "A modular and extensible wayland compositor";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
