{ python3
, fetchFromGitHub
, fontconfig
, lib
}:

python3.pkgs.buildPythonApplication {
  pname = "pt-p710bt-label-maker";
  version = "0-unstable-2024-02-07";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "jantman";
    repo = "pt-p710bt-label-maker";
    rev = "de4abf9e641aafa38907a0792f6d04c42ca24435";
    hash = "sha256-UtZFvK/783bzW4Lk3dReLpSHq3CZtjMMzD5jtoCRdrM=";
  };

  nativeBuildInputs = with python3.pkgs; [
    pythonRelaxDepsHook
    setuptools
  ];

  buildInputs = [
    fontconfig
  ];

  pythonRelaxDeps = [
    "pillow" # pillow<10.0.0,>=9.2.0
    "pypng" # pypng==0.0.20
    "python-barcode" # python-barcode==0.14.0
  ];

  dependencies = with python3.pkgs; [
    packbits
    pillow
    pybluez
    pypng
    python-barcode
    pyusb
  ];

  meta = with lib; {
    description = "P-Touch Cube (PT-P710BT) label maker";
    website = "https://github.com/jantman/pt-p710bt-label-maker";
    license = licenses.cc-by-40;
    mainProgram = "pt-label-printer";
  };
}
