{ rustPlatform
, fetchFromGitHub

, pkg-config

, blisp
, dfu-util
, gtk3
, openssl
, polkit
, udev

, lib
}:

rustPlatform.buildRustPackage rec {
  pname = "pineflash";
  version = "0.5.1";

  src = fetchFromGitHub {
    owner = "Spagett1";
    repo = "PineFlash";
    rev = version;
    hash = "sha256-99gmwhdVGYomX0g0W3BHoNbSdThVDZrjor3Z8PxHi6s=";
  };

  cargoLock.lockFile = src + "/Cargo.lock";

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [
    blisp
    dfu-util
    gtk3
    openssl
    polkit
    udev
  ];

  meta = with lib; {
    website = "https://github.com/Spagett1/PineFlash";
    description = "A tool to flash IronOS to the Pinecil soldering iron";
    license = licenses.gpl2;
  };
}
