{
  stdenvNoCC,
  fetchzip,
  fetchpatch,
  lib,
}:

stdenvNoCC.mkDerivation rec {
  pname = "mpv-uosc";
  version = "4.4.0";

  src = fetchzip {
    url = "https://github.com/tomasklaen/uosc/releases/download/${version}/uosc.zip";
    sha256 = "sha256-crto/Hcp80DvH1gXsDEAL4KIVgsZazCbic1Vry6bfx8=";
    stripRoot = false;
  };

  dontBuild = true;
  dontCheck = true;

  postPatch = ''
    substituteInPlace ./scripts/uosc.lua \
      --replace "mp.find_config_file('scripts')" "'$out/share/mpv/scripts'"
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/mpv
    ls -la ./fonts ./scripts
    cp -r ./fonts ./scripts $out/share/mpv
    runHook postInstall
  '';

  passthru.scriptName = "uosc.lua";

  meta = with lib; {
    description = "Feature-rich minimalist proximity-based UI for MPV player";
    homepage = "https://github.com/tomasklaen/uosc";
    license = licenses.gpl3;
  };
}
