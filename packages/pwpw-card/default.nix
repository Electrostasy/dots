{
  atk,
  autoPatchelfHook,
  cairo,
  fetchzip,
  gdk-pixbuf,
  glib,
  gobject-introspection,
  gtk3,
  lib,
  pango,
  pcsclite,
  stdenvNoCC,
}:

let
  version = "2.1.0.33";
  versionZip = builtins.replaceStrings [ "." ] [ "_" ] version;
in

stdenvNoCC.mkDerivation {
  pname = "pwpw-card";
  inherit version;

  src = fetchzip {
    url = "https://www.nsc.vrm.lt/files/pwpw_v${versionZip}_linux.zip";
    sha256 = "sha256-hi8TfcsPE6/xFdPJhsPFuxQ5y3RCdQgDTZTXwppMFf4=";
  };

  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [ autoPatchelfHook ];

  buildInputs = [
    atk
    cairo
    gdk-pixbuf
    glib
    gobject-introspection
    gtk3
    pango
    pcsclite
  ];

  installPhase = ''
    bash pwpw-card-${version}.linux.x64.run --target . --noexec
    mkdir $out
    cp -r lib usr/{bin,share} $out
    cp -r usr/lib64/* $out/lib
    ln -s $out/lib/pwpw-card-pkcs11.so $out/lib/libccpkip11.so
  '';

  fixupPhase = ''
    runHook preFixup
    patchShebangs $out/bin/{pwpw-card,pwpwcardm}
    patchShebangs $out/share/pwpwcardm/pwpwcardm.sh

    substituteInPlace \
      $out/bin/pwpwcardm \
      $out/share/pwpwcardm/pwpwcardm.sh \
      $out/lib/systemd/system/pwpwcardmon.service \
      --replace "/usr/bin" "$out/bin" \
      --replace "/usr/share" "$out/share"
    runHook postFixup
  '';

  meta = with lib; {
    description = "PKCS#11 driver for PWPW smart cards";
    homepage = "https://www.nsc.vrm.lt/downloads.htm";
    license = licenses.unfree;
    platforms = platforms.linux;
  };
}
