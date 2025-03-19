{ pkgs, lib, ... }:

{
  fonts = {
    enableDefaultPackages = false;

    # Override default Desktop Environment fonts.
    packages = with pkgs; lib.mkForce [
      inter
      ipaexfont
      liberation_ttf
      nerd-fonts.symbols-only
      recursive
      twemoji-color-font
    ];

    fontconfig = {
      defaultFonts = {
        monospace = [
          "Recursive Mn Lnr St"
          "Symbols Nerd Font Mono"
        ];
        sansSerif = [
          "Inter"
          "Liberation Sans"
          "IPAexGothic"
        ];
        serif = [
          "Liberation Serif"
          "IPAexMincho"
        ];
        emoji = [
          "Twitter Color Emoji SVGinOT"
        ];
      };

      localConf = /* xml */ ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
        <fontconfig>
          <match target="font">
            <test qual="any" name="family"><string>Inter</string></test>
            <!-- https://rsms.me/inter/#features -->
            <edit name="fontfeatures" mode="prepend">
              <!-- Contextural alternatives -->
              <string>calt off</string>
              <!-- Tabular numbers -->
              <string>tnum</string>
              <!-- Case alternates -->
              <string>case</string>
              <!-- Compositions -->
              <string>ccmp off</string>
              <!-- Disambiguation -->
              <string>ss02</string>
            </edit>
          </match>
          <match target="font">
            <test qual="any" name="family"><string>Recursive</string></test>
            <!-- https://github.com/arrowtype/recursive#opentype-features -->
            <edit name="fontfeatures" mode="prepend">
              <!-- Code ligatures -->
              <string>dlig off</string>
              <!-- Single-story 'a' -->
              <string>ss01</string>
              <!-- Single-story 'g' -->
              <string>ss02</string>
              <!-- Simplified mono 'at' -->
              <string>ss12</string>
              <!-- Uppercase punctuation -->
              <string>case</string>
              <!-- Slashed zero -->
              <string>ss20</string>
            </edit>
          </match>
        </fontconfig>
      '';
    };
  };
}
