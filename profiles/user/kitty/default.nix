{ config, pkgs, ... }:

{
  programs.kitty = {
    enable = true;
    settings = {
      cursor_shape = "beam";
      disable_ligatures = "always";
      scrollback_lines = 10000;
      enable_audio_bell = false;
      update_check_interval = 0;
      linux_display_server = "wayland";

      # https://github.com/kovidgoyal/kitty/discussions/4956
      confirm_os_window_close = 0;
    };
    # kitty list-fonts | rg 'Iosevka'
    extraConfig = ''
      font_family Iosevka Term
      bold_font Iosevka Term Bold Nerd Font Complete Mono
      italic_font Iosevka Term Italic Nerd Font Complete Mono
      bold_italic_font Iosevka Term Bold Italic Nerd Font Complete Mono
      font_size 11
      mouse_map ctrl+left press ungrabbed,grabbed mouse_click_url

      include ${pkgs.vimPlugins.kanagawa-nvim}/extras/kanagawa.conf
    '';
    keybindings = {
      "ctrl+shift+c" = "copy_to_clipboard";
      "ctrl+shift+v" = "paste_from_clipboard";
      "shift+up" = "scroll_line_up";
      "shift+down" = "scroll_line_down";
      "page_up" = "scroll_page_up";
      "page_down" = "scroll_page_down";
      "ctrl+shift+equal" = "change_font_size all +1.0";
      "ctrl+shift+minus" = "change_font_size all -1.0";
      "ctrl+shift+backspace" = "change_font_size all 0";
    };
  };
}
