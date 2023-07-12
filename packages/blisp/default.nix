{ stdenv
, fetchFromGitHub

, cmake
, pkg-config

, argtable
, libserialport

, lib
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "blisp";
  version = "unstable-2023-06-04";

  src = fetchFromGitHub {
    owner = "pine64";
    repo = finalAttrs.pname;
    rev = "048a72408218788d519a87bcdfb23bcf9ed91a84";
    hash = "sha256-hipJrr0D4uEN2hk8ooXeg0gv0X3w4U9ReXbC4oPEPwI=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    argtable
    libserialport
  ];

  cmakeFlags = [
    "-DBLISP_USE_SYSTEM_LIBRARIES=ON"
    "-DBLISP_BUILD_CLI=ON"
  ];

  installPhase = ''
    install -D -t $out/bin tools/blisp/blisp
  '';

  meta = with lib; {
    homepage = "https://github.com/pine64/blisp";
    description = "In-System Programming (ISP) tool for Bouffalo Labs RISC-V MCUs.";
    license = licenses.mit;
  };
})
