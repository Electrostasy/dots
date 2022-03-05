{ config, pkgs, lib, ... }:

{
  xdg.enable = true;

  home.packages = with pkgs; [
    firefox-custom # Customized firefox derivation
    grim # Image grabber
    iosevka-nerdfonts
    liberation_ttf # Replacement fonts for TNR, Arial and Courier New
    (libreoffice.overrideAttrs (old: { langs = [ "en-US" "lt" ]; })) # Office suite
    quintom-cursor-theme # X Cursor theme
    ripgrep # `grep` alternative
    slurp # Region selector
    source-han-sans # Japanese OpenType/CFF fonts
    tealdeer # `tldr` alternative
    wl-clipboard # `wl-{copy,paste}` clipboard utilities
    xplr # TUI scriptable file manager
    xwayland # Legacy X11 glue
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

    kitty = {
      enable = true;
      settings = {
        cursor_shape = "beam";
        disable_ligatures = "always";
        scrollback_lines = 10000;
        enable_audio_bell = false;
        update_check_interval = 0;
        linux_display_server = "wayland";
      };
      extraConfig = ''
        font_family Iosevka
        bold_font Iosevka Bold
        italic_font Iosevka Italic
        bold_italic_font Iosevka Bold Italic
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

    fish = {
      enable = true;

      shellAliases.ssh = lib.mkIf config.programs.kitty.enable "kitty +kitten ssh";
      shellAbbrs = with lib; {
        n = mkIf config.programs.neovim.enable "nvim";
        z = mkIf config.programs.zathura.enable "zathura";
        x = mkIf (any (elem: elem == pkgs.xplr) config.home.packages) "xplr";
      };
      functions = {
        fish_greeting = "
          if isatty stdout; set_color $fish_color_comment; end; \\
          ${pkgs.fortune}/bin/fortune definitions";
      };
      # Use kanagawa theme
      interactiveShellInit = ''
        source ${pkgs.vimPlugins.kanagawa-nvim}/extras/kanagawa.fish
      '';
      loginShellInit = ''
        set EDITOR nvim
        set VISUAL nvim
        set PAGER less
      '';
    };

    git = {
      enable = true;
      userName = "Gediminas Valys";
      userEmail = "steamykins@gmail.com";
    };
  };
}

