{ bison
, check
, fetchFromGitHub
, flex
, gdk-pixbuf
, lib
, librsvg
, libstartup_notification
, libxkbcommon
, meson
, ninja
, pango
, pkg-config
, stdenv
, wayland
, wayland-protocols
, xcb-util-cursor
, xcbutilwm
}:

stdenv.mkDerivation {
  pname = "rofi-wayland-unwrapped";
  version = "1.7.1";

  src = fetchFromGitHub {
    owner = "lbonn";
    repo = "rofi";
    rev = "0a0d8333ca28e4a1093adfd0c0b2b2301c34625b";
    sha256 = "INFYHOVjBNj8ks4UjKnxLW8mL7h1c8ySFPS/rUxOWwo=";
    fetchSubmodules = true;
  };
  
  CFLAGS="-Wno-overlength-strings";

  preConfigure = ''
    patchShebangs "script"
    # root not present in build /etc/passwd
    sed -i 's/~root/~nobody/g' test/helper-expand.c
  '';

  nativeBuildInputs = [ ninja meson pkg-config ];
  buildInputs = [
    bison
    check
    flex
    gdk-pixbuf
    libstartup_notification
    libxkbcommon
    pango
    wayland
    wayland-protocols
    xcb-util-cursor
    xcbutilwm
  ];

  mesonFlags = [ "-Dwayland=enabled" ];

  doCheck = true;

  meta = with lib; {
    description = "Window switcher, run dialog and dmenu replacement (built for Wayland)";
    homepage = "https://github.com/lbonn/rofi";
    license = licenses.mit;
    platforms = with platforms; linux;
  };
}
