{ pkgs, ... }:

{
  xdg.enable = true;

  home.packages = with pkgs; [
    firefox-custom
    iosevka-nerdfonts
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

    lsd = {
      enable = true;

      settings = {
        classic = false;
        blocks = [ "permission" "user" "group" "size" "date" "name" ];
        date = "+%Y-%m-%d %H:%M:%S %z";
        dereference = true;
        sorting = {
          column = "name";
          dir-grouping = "first";
        };
      };
    };
  };
}

