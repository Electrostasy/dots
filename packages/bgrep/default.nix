{
  stdenv,
  fetchFromGitHub,
  lib,
}:

stdenv.mkDerivation {
  pname = "bgrep";
  version = "unstable-2021-04-10";

  src = fetchFromGitHub {
    owner = "tmbinc";
    repo = "bgrep";
    rev = "28029c9203d54f4fc9332d094927cd82154331f2";
    sha256 = "sha256-gAtxAJ1z9mXViEyQ0WedjuBDg5jqUvAS51axbx3SOGM=";
  };

  buildPhase = ''
    ${stdenv.cc}/bin/gcc -O2 -x c -o bgrep bgrep.c
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp bgrep $out/bin
  '';

  meta = with lib; {
    description = "Binary Grep";
    homepage = "https://github.com/tmbinc/bgrep";
    # Redistributable with or without modifications, so long as there is
    # attribution and conditions (no warranties, liability) are met.
    license = licenses.free;
  };
}
