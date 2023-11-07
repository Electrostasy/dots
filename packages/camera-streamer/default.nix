{ stdenv
, fetchFromGitHub

, cmake
, gnumake
, pkg-config
, xxd

, v4l-utils
, nlohmann_json
, ffmpegSupport ? true
, ffmpeg
, libcameraSupport ? true
, libcamera
, rtspSupport ? true
, live555
, webrtcSupport ? true
, openssl

, lib
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "camera-streamer";
  version = "0.2.7";

  src = fetchFromGitHub {
    owner = "ayufan";
    repo = finalAttrs.pname;
    rev = "refs/tags/v${finalAttrs.version}";
    hash = "sha256-ZD3ixSamunm7E+b83ewVBB45/uYLAbDYzqJygFBU4lc=";
    fetchSubmodules = true;
  };

  # Second replacement fixes literal newline in generated version.h.
  postPatch = ''
    substituteInPlace Makefile \
      --replace '/usr/local/bin' '/bin' \
      --replace 'echo "#define' 'echo -e "#define'
  '';

  env.NIX_CFLAGS_COMPILE = builtins.toString [
    "-Wno-error=stringop-overflow"
    "-Wno-error=format"
    "-Wno-format"
    "-Wno-format-security"
    "-Wno-error=unused-result"
  ];

  nativeBuildInputs = [
    cmake
    gnumake
    pkg-config
    xxd
  ];

  dontUseCmakeConfigure = true;

  buildInputs = [ nlohmann_json v4l-utils ]
    ++ (lib.optional ffmpegSupport ffmpeg)
    ++ (lib.optional libcameraSupport libcamera)
    ++ (lib.optional rtspSupport live555)
    ++ (lib.optional webrtcSupport openssl);

  installFlags = [ "DESTDIR=${builtins.placeholder "out"}" ];
  preInstall = "mkdir -p $out/bin";

  meta = with lib; {
    description = "High-performance low-latency camera streamer for Raspberry Pi's";
    website = "https://github.com/ayufan/camera-streamer";
    license = licenses.gpl3Only;
  };
})
