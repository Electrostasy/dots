{ stdenv
, fetchFromGitHub
, meson
, ninja
, pkg-config
, boost
, ffmpeg
, libcamera
, libdrm
, libexif
, libjpeg
, libpng
, libtiff
, lib
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "rpicam-apps";
  version = "1.4.1";

  src = fetchFromGitHub {
    owner = "raspberrypi";
    repo = finalAttrs.pname;
    rev = "v" + finalAttrs.version;
    hash = "sha256-3NG2ZE/Ub3lTbfne0LCXuDgLGTPaAAADRdElEbZwvls=";
  };

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
  ];

  buildInputs = [
    boost
    ffmpeg
    libcamera
    libdrm
    libexif
    libjpeg
    libpng
    libtiff
  ];

  # Meson is no longer able to pick up Boost automatically:
  # https://github.com/NixOS/nixpkgs/issues/86131
  BOOST_INCLUDEDIR = "${lib.getDev boost}/include";
  BOOST_LIBRARYDIR = "${lib.getLib boost}/lib";

  meta = with lib; {
    description = ''
      libcamera-based applications to drive the cameras on a Raspberry Pi platform
    '';
    homepage = "https://github.com/raspberrypi/libcamera-apps";
    license = licenses.bsd2;
  };
})
