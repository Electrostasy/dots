{ pkgs, ... }:

{
  home.stateVersion = "22.11";

  xdg.enable = true;

  home.packages = with pkgs; [
    firefox-custom
    (nerdfonts.override { fonts = [ "Iosevka" ]; })
    liberation_ttf # Replacement fonts for TNR, Arial and Courier New
    (libreoffice.overrideAttrs (old: { langs = [ "en-US" "lt" ]; }))
    source-han-sans # Japanese OpenType/CFF fonts
    xplr
  ];

  fonts.fontconfig.enable = true;

  programs = {
    zathura.enable = true;

    rofi = {
      enable = true;

      package = pkgs.rofi-wayland;
      plugins = [ ];
      terminal = "${pkgs.kitty}/bin/kitty";
      extraConfig = {
        modi = "drun,run";
        kb-primary-paste = "Control+V";
        kb-secondary-paste = "Control+v";
      };
    };
  };
}

