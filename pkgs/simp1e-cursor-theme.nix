{ stdenvNoCC, fetchFromGitLab, librsvg, python3Packages, xcursorgen, lib }:

stdenvNoCC.mkDerivation {
  pname = "simp1e-cursor-theme";
  version = "unstable-2022-03-18";

  src = fetchFromGitLab {
    owner = "zoli111";
    repo = "simp1e";
    rev = "f3aa2abe9db94cba3c87b0bb6651fac656d30e3e";
    hash = "sha256-Nq2A8TB1o17993ozlrR5vuMj1qMeSeh3n04KaQjG1/E=";
    fetchSubmodules = true;
  };

  phases = [ "unpackPhase" "buildPhase" "installPhase" ];

  buildInputs = [ librsvg python3Packages.pillow xcursorgen ];

  buildPhase = ''
    for builder in ./generate_svgs.sh ./build_cursors.sh; do
      patchShebangs --build "$builder"
      bash -c "$builder"
    done
  '';

  installPhase = ''
    mkdir -p "$out/share/icons"
    for theme in ./built_themes/*; do
      cp -r "$theme" "$out/share/icons/"
    done
  '';

  meta = with lib; {
    description = "An aesthetic cursor theme for your Linux desktop";
    homepage = "https://gitlab.com/zoli111/simp1e";
    platforms = platforms.unix;
    license = licenses.gpl3Only;
  };
}
