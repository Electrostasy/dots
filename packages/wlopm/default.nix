{ stdenv, fetchFromSourcehut, gnumake, wayland, wayland-scanner }:

stdenv.mkDerivation {
  pname = "wlopm";
  version = "unstable-2021-01-31";

  src = fetchFromSourcehut {
    owner = "~leon_plickat";
    repo = "wlopm";
    rev = "27b7ccd1f1f2f5f2986508890805934c3e7614ee";
    sha256 = "sha256-LgS+JJZgoJt0fWxSKfW98rHBNjZk9Z8aGUci0Ftx92Y=";
  };

  installPhase = ''
    make install PREFIX=$out
  '';

  nativeBuildInputs = [
    gnumake wayland wayland-scanner
  ];

  buildInputs = [ wayland ];
}
