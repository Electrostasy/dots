{ stdenv
, fetchFromGitHub
, meson
, ninja
, pkg-config
, wayfire
, cairo
, libGL
, libxkbcommon
, pango
, wayland
, wf-config
, wlroots
, lib
}:

stdenv.mkDerivation {
  pname = "wayfire-shadows";
  version = "unstable-2023-09-08";

  src = fetchFromGitHub {
    owner = "timgott";
    repo = "wayfire-shadows";
    rev = "de3239501fcafd1aa8bd01d703aa9469900004c5";
    sha256 = "sha256-oVlSzpddPDk6pbyLFMhAkuRffkYpinP7jRspVmfLfyA=";
  };

  postPatch = ''
    substituteInPlace meson.build \
      --replace "wayfire.get_variable( pkgconfig: 'metadatadir' )" "join_paths(get_option('prefix'), 'share/wayfire/metadata')"
  '';

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
  ];

  buildInputs = [
    cairo
    libGL
    libxkbcommon
    pango
    wayfire
    wayland
    wf-config
    wlroots
  ];

  meta = with lib; {
    website = "https://github.com/timgott/wayfire-shadows";
    description = "Wayfire plugin that adds window shadows";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
