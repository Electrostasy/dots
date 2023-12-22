{ stdenvNoCC
, fetchzip
, python3
}:

stdenvNoCC.mkDerivation {
  pname = "pt-p300bt-labelmaker";
  version = "unstable-2020-12-21";

  src = fetchzip {
    url = "https://gist.github.com/dogtopus/64ae743825e42f2bb8ec79cea7ad2057/archive/master.zip";
    hash = "sha256-spUVnZ+fgzjR98+7OtBIODstJwDop/bCPvMVVxPf0Xc=";
  };

  propagatedBuildInputs = [
    (python3.withPackages (ps: with ps; [
      pybluez
      pillow
      packbits
    ]))
  ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin"
    install -m755 {labelmaker,labelmaker_encode}.py "$out/bin"
    # These are libraries used by the above scripts. They probably don't belong
    # in $out/bin, but I have no idea how to move them, so they will be invisible.
    install -m444 {ptcbp,ptstatus}.py "$out/bin"
    runHook postInstall
  '';

  meta = {
    description = "Brother P-Touch PT-P300BT Bluetooth driver in Python";
    website = "https://gist.github.com/dogtopus/64ae743825e42f2bb8ec79cea7ad2057";
  };
}
