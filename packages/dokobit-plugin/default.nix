{
  autoPatchelfHook,
  dpkg,
  fetchurl,
  lib,
  libstdcxx5,
  openssl,
  qt5,
  stdenv,
}:

stdenv.mkDerivation rec {
  pname = "dokobit-plugin";
  version = "1.3.14.0";

  src = fetchurl {
    url = "https://github.com/dokobit/browser-plugin/raw/master/Linux/64Bit/dokobit-plugin-en_${version}.deb";
    sha256 = "sha256-S/OiLYO+oQezx2ctcJXh/guP+4fFLThZUE5El0MA8CA=";
  };

  dontBuild = true;
  dontConfigure = true;

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    qt5.wrapQtAppsHook
  ];

  buildInputs = [
    openssl
    qt5.qtbase
    qt5.qtnetworkauth
  ];

  unpackPhase = ''
    dpkg-deb --extract $src dokobit
    sourceRoot=dokobit
  '';

  installPhase = ''
    runHook preinstall
    mkdir $out
    cp -r etc $out
    cp -r usr/* $out
    # TODO: Don't use bundled OpenSSL
    ln -sf $out/lib/dokobit-plugin/libcrypto.so $out/lib/dokobit-plugin/libcrypto.so.1.0.0
    runHook postinstall
  '';

  preFixup = ''
    substituteInPlace \
      $out/lib/mozilla/native-messaging-hosts/lt.isign.chromesigning.json \
      $out/share/dokobit-plugin/lt.isign.chromesigning.json \
      $out/share/doc/dokobit-plugin/copyright \
      --replace "/usr/bin" "$out/bin" \
      --replace "/usr/share" "$out/share"
  '';

  meta = with lib; {
    description = "Google Chrome & Mozilla Firefox native smartcard plugin for Dokobit";
    homepage = "https://www.dokobit.com/downloads";
    license = licenses.unfree;
    platforms = platforms.linux;
  };
}
