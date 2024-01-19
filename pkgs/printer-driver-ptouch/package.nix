# This derivation provides the necessary *.ppd printer drivers for the Brother
# P-Touch line of printers (and others) under CUPS. I was specifically testing
# the Brother PT-P300BT (Brother P-Touch Cube) using this configuration:
# {
#   hardware = {
#     bluetooth.enable = true;
#     printers.ensurePrinters = [
#       {
#         name = "Brother_P_Touch_Cube";
#         model = "printer-driver-ptouch/Brother-PT-P300BT-ptouch-pt.ppd";
#         deviceUri = "bluetooth://<mac_of_your_p300bt>/spp";
#       }
#     ];
#   };
#   services.printing = {
#     enable = true;
#     drivers = with pkgs; [
#       (config.hardware.bluetooth.package)
#       printer-driver-ptouch
#     ];
#   };
# }
# The above successfully sets up the PT-P300BT with CUPS using the Bluetooth
# backend provided by bluez, however, I could not get it to print correctly,
# likely needs more work compared to the scripts the PT-P300BT patch was based on.

{
  stdenv,
  fetchFromGitHub,
  perl,
  autoconf,
  automake,
  foomatic-db-engine,
  cups,
  ghostscript,
  libpng,
  lib,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "printer-driver-ptouch";
  version = "unstable-2023-09-27";

  src = fetchFromGitHub {
    owner = "philpem";
    repo = finalAttrs.pname;
    rev = "9f75468dd4e7e73770bfbafed79a05b3585ca28d";
    hash = "sha256-IMMLQj5+r842dh1kMV+yI7efewttyBG+SKyrPLtJEVk=";
  };

  postPatch = ''
    patchShebangs foomaticalize
  '';

  nativeBuildInputs = [
    (perl.withPackages (ps: [ps.XMLLibXML]))
    autoconf
    automake
    foomatic-db-engine
  ];

  buildInputs = [
    cups
    ghostscript
    libpng
  ];

  preConfigure = ''
    autoreconf -fi
  '';

  postInstall = ''
    mkdir -p "$out/share/cups/model"
    FOOMATICDB="$out/share/foomatic" foomatic-compiledb -j "$NIX_BUILD_CORES" -d "$out/share/cups/model/printer-driver-ptouch"
    rm -rf "$out/share/foomatic"
  '';

  meta = with lib; {
    website = "https://github.com/philpem/printer-driver-ptouch";
    description = "P-Touch PT-series and QL-series printer driver for Linux (under CUPS)";
    license = licenses.gpl2;
  };
})
