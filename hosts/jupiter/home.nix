{ pkgs, ... }:

{
  home.stateVersion = "22.11";

  xdg.enable = true;

  home.packages = with pkgs; [
    firefox-custom
    iosevka-nerdfonts
    liberation_ttf # Replacement fonts for TNR, Arial and Courier New
    libreoffice
    source-han-sans # Japanese OpenType/CFF fonts
    xplr
  ];

  fonts.fontconfig.enable = true;
}

