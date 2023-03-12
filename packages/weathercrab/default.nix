{
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  openssl,
  lib,
}:

rustPlatform.buildRustPackage rec {
  pname = "wthrr-the-weathercrab";
  version = "1.0.0-rc";

  src = fetchFromGitHub {
    owner = "tobealive";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-6zVp6JlGAGQY8HNk2qVtkTQGC9AFaQ9kpD15c2v2Jk0=";
  };

  cargoLock.lockFile = "${src}/Cargo.lock";

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [ openssl ];

  checkFlags = [
    # These tests require an internet connection to https://translate.googleapis.com
    # and https://geocoding-api.open-meteo.com during the checkPhase.
    "--skip=modules::localization::tests::translate_string"
    "--skip=modules::location::tests::geolocation_response"
  ];

  meta = with lib; {
    description = "Weather companion for the terminal";
    homepage = "https://github.com/tobealive/wthrr-the-weathercrab";
    license = licenses.mit;
    mainProgram = "wthrr";
  };
}
