{ fetchurl, stdenv }:

stdenv.mkDerivation {
  pname = "umc";
  version = "0.2";

  src = fetchurl {
    url = "mirror://sourceforge/umc/umc-0.2/umc-0.2.tar.gz";
    sha256 = "sha256-QgFn2DRRNnw5Y106nVwj9lwnk7QQ8E8Fa6NHQJgmSz4=";
  };
}
