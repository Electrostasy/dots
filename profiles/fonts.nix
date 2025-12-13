{ pkgs, lib, ... }:

{
  fonts = {
    enableDefaultPackages = false;

    # Override default Desktop Environment fonts.
    packages = with pkgs; lib.mkForce [
      inter
      liberation_ttf
      nerd-fonts.symbols-only
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      recursive
      twemoji-color-font
    ];

    fontconfig = {
      defaultFonts = {
        monospace = [
          "Recursive Mn Lnr St"
          "Symbols Nerd Font Mono"
          "Noto Sans Mono CJK JP"
          "Noto Sans Mono CJK KR"
          "Noto Sans Mono CJK SC"
          "Noto Sans Mono CJK TC"
          "Noto Sans Mono CJK HK"
        ];
        sansSerif = [
          "Inter"
          "Liberation Sans"
          "Noto Sans CJK JP"
          "Noto Sans CJK KR"
          "Noto Sans CJK SC"
          "Noto Sans CJK TC"
          "Noto Sans CJK HK"
        ];
        serif = [
          "Liberation Serif"
          "Noto Serif CJK JP"
          "Noto Serif CJK KR"
          "Noto Serif CJK SC"
          "Noto Serif CJK TC"
          "Noto Serif CJK HK"
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
