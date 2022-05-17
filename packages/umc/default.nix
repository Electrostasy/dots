{ fetchzip, stdenv }:

stdenv.mkDerivation {
  pname = "umc";
  version = "0.2";

  src = fetchzip {
    url = "mirror://sourceforge/umc/umc/umc-0.2/umc-0.2.tar.gz";
    sha256 = "sha256-N4AVvViMgZAmxS5EI9fqaxeKFZK7Qa+rfd1h4NqMFrE=";
  };
}
