{ pkgs, ... }:

{
  fonts.fontconfig.enable = true;

  # Prefer custom build of Iosevka and have missing glyphs fallback to nerdfonts.
  # We can't fallback to the complete nerdfonts unpatched font because Iosevka
  # is more narrow and so the glyphs are bigger and can get cut off
  xdg.configFile."fontconfig/conf.d/20-iosevka-nerdfonts.conf".text = ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>
      <alias>
        <family>Iosevka Custom</family>
        <prefer>
          <family>Iosevka Custom</family>
          <family>Iosevka Nerd Font</family>
        </prefer>
      </alias>
    </fontconfig>
  '';

  home.packages = with pkgs; [
    iosevka-custom
    (nerdfonts.override { fonts = [ "Iosevka" ]; })
  ];

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

      # Should be fixed when 0.26.3+ lands:
      # https://github.com/kovidgoyal/kitty/issues/5467
      # https://sw.kovidgoyal.net/kitty/changelog/#id3
      remember_window_size = "no";
      initial_window_width = 850;
      initial_window_height = 540;
    };

    extraConfig = ''
      font_family Iosevka Custom
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
