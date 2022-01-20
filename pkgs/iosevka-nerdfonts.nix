{
  stdenv,
  nerd-font-patcher,
  iosevka ? iosevka.override {
    privateBuildPlan = {
      family = "Iosevka Custom";
      spacing = "normal";
      serifs = "sans";
      no-cv-ss = true;
      no-litigation = true;
    };
    set = "custom";
  }
}:

stdenv.mkDerivation {
  pname = "iosevka-nerdfonts";
  version = iosevka.version;
  src = null;

  nativeBuildInputs = [ nerd-font-patcher iosevka ];
  phases = [ "buildPhase" ];

  buildPhase = ''
    mkdir -p $out/share/fonts/truetype
    cp -r ${iosevka}/share/fonts/truetype $out/share/fonts/truetype
    cd $out/share/fonts/truetype
    find \
      -name \*.ttf \
      -exec ${nerd-font-patcher}/bin/nerd-font-patcher --use-single-width-glyphs --adjust-line-height --complete {} \;
  '';
}
