{ stdenv
, fetchFromGitHub
, cmake
, pkg-config

, libcamera
, boost
, libexif
, libjpeg
, libtiff
, libpng

, lib
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libcamera-apps";
  version = "1.1.2";

  src = fetchFromGitHub {
    owner = "raspberrypi";
    repo = finalAttrs.pname;
    rev = "v" + finalAttrs.version;
    hash = "sha256-A6UriYk8bHRL6wp6ehXOnUnbJH2/mNDkxwGemD/UYpw=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    libcamera
    boost
    libexif
    libjpeg
    libtiff
    libpng
  ];

  meta = with lib; {
    description = "libcamera-based apps that copy the functionality of existing raspicam apps";
    homepage = "https://github.com/raspberrypi/libcamera-apps";
    license = licenses.bsd2;
  };
})
