{
  stdenvNoCC,
  fetchFromGitHub,
  fetchpatch,
}:

stdenvNoCC.mkDerivation rec {
  pname = "mpv-osc-tethys";
  version = "unstable-2022-11-18";

  src = fetchFromGitHub {
    owner = "Zren";
    repo = pname;
    rev = "5b0a5a80f669b104f7634c20f60751ae7bb713c5";
    sha256 = "sha256-wqlIr/TevgLy6E8mfC/JrmQ6dwy/OAVdI9ulEZsFPk8=";
  };

  patches = [
    (fetchpatch {
      url = "https://github.com/Zren/mpv-osc-tethys/pull/24.patch";
      sha256 = "sha256-pHE0IqsoL4nkFVbdGozJsLkosbYAYEDU1kq6Y1zRrKc=";
    })
  ];

  dontBuild = true;
  dontCheck = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/mpv/scripts
    cp osc_tethys.lua mpv_thumbnail_script_server.lua $out/share/mpv/scripts
    runHook postInstall
  '';

  passthru.scriptName = "osc_tethys.lua";

  meta = {
    description = "OSC UI replacement for MPV with icons from the bomi video player";
    homepage = "https://github.com/Zren/mpv-osc-tethys";
  };
}
