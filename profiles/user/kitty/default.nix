{ pkgs, ... }:

{
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
    recursive
  ];

  programs.kitty = {
    enable = true;

    settings = {
      cursor_shape = "beam";
      disable_ligatures = "always";
      scrollback_lines = 10000;
      enable_audio_bell = false;
      update_check_interval = 0;
      undercurl_style = "thick-sparse";

      # https://github.com/kovidgoyal/kitty/discussions/4956
      confirm_os_window_close = 0;
    };

    extraConfig = ''
      symbol_map U+23FB-U+23FE,U+2665,U+26A1,U+2B58,U+E000-U+E00A,U+E0A0-U+E0A3,U+E0B0-U+E0C8,U+E0CA,U+E0CC-U+E0D2,U+E0D4,U+E200-U+E2A9,U+E300-U+E3E3,U+E5FA-U+E634,U+E700-U+E7C5,U+EA60-U+EBEB,U+F000-U+F2E0,U+F300-U+F32F,U+F400-U+F4A9,U+F500-U+F8FF Symbols-1000-em Nerd Font Complete Mono
      font_family Rec Mono Duotone
      font_size 10
      mouse_map ctrl+left press ungrabbed,grabbed mouse_click_url

      include ${pkgs.vimPlugins.kanagawa-nvim}/extras/kanagawa.conf
    '';

    keybindings = {
      "ctrl+shift+c" = "copy_to_clipboard";
      "ctrl+shift+v" = "paste_from_clipboard";
      "shift+up" = "scroll_line_up";
      "shift+down" = "scroll_line_down";
      "ctrl+shift+equal" = "change_font_size all +1.0";
      "ctrl+shift+minus" = "change_font_size all -1.0";
      "ctrl+shift+backspace" = "change_font_size all 0";
    };
  };
}
