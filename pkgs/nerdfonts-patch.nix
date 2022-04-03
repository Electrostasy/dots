{ nerd-font-patcher,
  parallel-full,
  stdenv,
}:

font:

stdenv.mkDerivation {
  pname = "${font.pname}-nerdfonts";
  inherit (font) version;
  src = null;

  nativeBuildInputs = [ font nerd-font-patcher (parallel-full.override { willCite = true; }) ];
  phases = [ "buildPhase" ];

  buildPhase = ''
    mkdir -p $out/share/fonts/truetype
    cp -r ${font}/share/fonts/truetype $out/share/fonts/truetype
    cd $out/share/fonts/truetype
    find -name \*.ttf | parallel ${nerd-font-patcher}/bin/nerd-font-patcher --use-single-width-glyphs --adjust-line-height --complete {}
  '';
}
