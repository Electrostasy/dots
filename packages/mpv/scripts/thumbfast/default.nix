{
  stdenvNoCC,
  fetchFromGitHub,
}:

stdenvNoCC.mkDerivation {
  pname = "mpv-thumbfast";
  version = "unstable-2022-11-16";

  src = fetchFromGitHub {
    owner = "po5";
    repo = "thumbfast";
    rev = "08d81035bb5020f4caa326e642341f2e8af00ffe";
    sha256 = "sha256-T+9RxkKWX6vwDNi8i3Yq9QXSJQNwsHD2mXOllaFuSyQ=";
  };

  dontBuild = true;
  dontCheck = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/mpv/scripts
    cp -r ./thumbfast.lua $out/share/mpv/scripts
    runHook postInstall
  '';

  passthru.scriptName = "thumbfast.lua";

  meta = {
    description = "High-performance on-the-fly thumbnailer for mpv";
    homepage = "https://github.com/po5/thumbfast";
  };
}
