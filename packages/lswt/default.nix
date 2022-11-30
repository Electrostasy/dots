{
  stdenv,
  fetchFromSourcehut,
  gnumake,
  wayland,
  lib,
}:

stdenv.mkDerivation rec {
  pname = "lswt";
  version = "1.0.4";

  src = fetchFromSourcehut {
    owner = "~leon_plickat";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-Orwa7sV56AeznEcq/Xj5qj4PALMxq0CI+ZnXuY4JYE0=";
  };

  makeFlags = [ "PREFIX=${builtins.placeholder "out"}" ];
  nativeBuildInputs = [ gnumake ];

  buildInputs = [ wayland ];

  meta = with lib; {
    description = "List Wayland toplevels";
    homepage = "https://sr.ht/~leon_plickat/lswt";
    license = licenses.gpl3;
  };
}
