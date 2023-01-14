{
  stdenvNoCC,
  fetchFromGitea,
  lib,
}:

stdenvNoCC.mkDerivation {
  pname = "mpv-mfpbar";
  version = "unstable-2023-01-02";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "NRK";
    repo = "mpv-toolbox";
    rev = "0ebdc64436cf2ec8cc3bacb49740758102782f29";
    sha256 = "sha256-5x7ILVJ3g64nLmlji+2OhYAq2uQycse8lKTeBq0k3kQ=";
  };

  dontBuild = true;
  dontCheck = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/mpv/scripts
    cp $src/mfpbar/mfpbar.lua $out/share/mpv/scripts
    runHook postInstall
  '';

  passthru.scriptName = "mfpbar.lua";

  meta = with lib; {
    description = ''
      Progress-bar with minimal visual-clutter, features as well as code-size for the MPV player
    '';
    homepage = "https://codeberg.org/NRK/mpv-toolbox";
    license = licenses.agpl3;
  };
}
