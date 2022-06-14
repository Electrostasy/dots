{
  buildGoPackage,
  fetchFromGitHub,
  lib,
}:

buildGoPackage rec {
  pname = "opensmtpd-senderscore";
  version = "unstable-2021-08-14";

  goPackagePath = "https://github.com/poolpOrg/filter-senderscore";

  src = fetchFromGitHub {
    owner = "poolpOrg";
    repo = "filter-senderscore";
    rev = "e90a24941bf3f1fec2d4ddaca7b341796f8bc00f";
    sha256 = "sha256-lIdj65FekCV3urxTm2gsm0ws0KepuvP+KKGNDlWTyPg=";
  };

  meta = with lib; {
    description = "OpenSMTPD filter integration for the SenderScore reputation";
    homepage = goPackagePath;
    license = licenses.isc;
    maintainers = [ ];
  };
}
