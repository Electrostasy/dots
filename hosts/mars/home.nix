{ config, pkgs, lib, ... }:

{
  xdg.enable = true;

  home.packages = with pkgs; [
    alsaUtils
    bottom # System resources monitor
    chafa # Image data terminal previewer
    du-dust # Disk usage visualizer
    eww-wayland # Desktop widgets
    f3d # 3D file format viewer
    ffmpeg
    firefox-custom
    gimp
    grim # Wayland compositor image grabber
    imagemagick
    inter # UI typeface
    iosevka-nerdfonts
    keepassxc # Password manager
    liberation_ttf # Replacement fonts for TNR, Arial and Courier New
    (libreoffice.overrideAttrs (_: { langs = [ "en-US" "lt" ]; }))
    neofetch
    pastel # Generate, analyze, convert and manipulate colours
    quintom-cursor-theme
    # rink # Unit-aware calculator/conversion tool
    ripgrep
    schildichat-desktop-wayland # Matrix chat client
    slurp # Wayland compositor region selector
    source-han-sans # Japanese OpenType/CFF fonts
    # swayidle # Idle management daemon
    # swaylock # Screen locker
    tealdeer # `tldr` alternative
    # (texlive.combine { inherit (texlive) scheme-minimal lithuanian hyphen-lithuanian collection-langenglish; })
    transmission-qt # BitTorrent client
    wf-recorder # Record wayland displays
    wl-clipboard # `wl-{copy,paste}` clipboard utilities
    xplr # TUI scriptable file manager
    xwayland
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
        reboot-windows = ''
          set -l windows (${pkgs.efibootmgr}/bin/efibootmgr | grep 'Windows Boot Manager')
          if [ "$status" -eq 1 ]
            echo 'Cannot reboot into Windows: Windows not found'
          else
            for text in "Rebooting into Windows in 3..." "2..." "1..."
              echo -n "$text" && sleep 1
            end
            set -l next_boot (echo "$windows" | cut -d '*' -f1 | cut -c 5-)
            if sudo ${pkgs.efibootmgr}/bin/efibootmgr -n "$next_boot"
              reboot
            end
          end
        '';
        share-screen = ''
          set -l intro 'Select a display to begin sharing to /dev/video0.\nOnce selected, "mpv --demuxer-lavf-format=video4linux2 av://v4l2:/dev/video0" to preview.'
          set -l command "echo $intro; wf-recorder --muxer=v4l2 --file=/dev/video0 -c rawvideo -o (slurp -o -f \"%o\") -x yuyv422"

          kitty fish -c "$command"
        '';
        qr = {
          description = ''
            Encode clipboard contents as a QR code, or decode a QR code from selected screen region
          '';
          body = ''
            argparse -x e,d 'e/encode' 'd/decode' -- $argv
            if set -q _flag_encode
              echo (${pkgs.wl-clipboard}/bin/wl-paste) | ${pkgs.qrencode}/bin/qrencode -t ansiutf8
              return 0
            end
            if set -q _flag_decode
              ${pkgs.grim}/bin/grim -g (${pkgs.slurp}/bin/slurp) - | ${pkgs.zbar}/bin/zbarimg -q --raw PNG:
              return 0
            end
            echo 'Usage:'
            echo '  -e/--encode: encode clipboard'
            echo '  -d/--decode: decode selected region'
            return 1
          '';
        };
        fish_greeting = ''
          if isatty stdout
            set_color $fish_color_comment
          end; ${pkgs.fortune}/bin/fortune definitions
        '';
      };
      interactiveShellInit = ''
        source ${pkgs.vimPlugins.kanagawa-nvim}/extras/kanagawa.fish
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

