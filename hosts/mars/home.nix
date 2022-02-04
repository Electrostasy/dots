{ config, pkgs, lib, ... }:

{
  xdg.enable = true;

  home.packages = with pkgs; let
    # General CLI utilities used from the terminal or in scripts
    shellPkgs = [
      alsaUtils # ALSA audio utility programms
      # fd # `find` alternative
      # git # Version control
      # hexyl # Hex viewer
      imagemagick # Image processor
      # libnotify # `notify-send` notifications utility
      # most # Pager
      neofetch # System information fetcher
      # pass # Password manager
      # pciutils # PCI device utility programs
      ripgrep # `grep` alternative
      tealdeer # `tldr` alternative
      xplr # TUI scriptable file manager
      pastel # Generate, analyze, convert and manipulate colours
      chafa # Image data terminal previewer
      # tomb # File and directory encryption
      # kalker # Math syntax calculator
      # rink # Unit-aware calculator/conversion tool
      du-dust # Disk usage visualizer
      ffmpeg # Audio/video recording, converting and streaming tool
      (pkgs.writeShellScriptBin "steam" ''
        if [[ "$(nixos-container status steam)" == "down" ]]; then
          sudo nixos-container start steam
        fi
        if sudo nixos-container run steam -- runuser steam -c 'cd /; /run/wrappers/bin/gamescope -w 3840 -h 2160 -r 120 -e -- capsh --noamb -- steam -tenfoot -steamos -fulldesktopres'; then
          sudo nixos-container stop steam
        fi
      '')
      # (texlive.combine { inherit (texlive) scheme-minimal lithuanian hyphen-lithuanian collection-langenglish; })
    ];
    # CLI utilities specific to Wayland compositing servers
    waylandPkgs = [
      grim # Image grabber
      slurp # Region selector
      swaybg # Output background setter
      # swayidle # Idle management daemon
      # swaylock # Screen locker
      # tiramisu # Notification reader/handler
      wl-clipboard # `wl-{copy,paste}` clipboard utilities
      wlr-randr # Outputs querying and management
      xwayland # Legacy X11 glue
      wf-recorder # Record wayland displays
    ];
    # Graphical programs, fonts and icons
    graphicalPkgs = [
      # wdisplays # Graphical output management
      (libreoffice.overrideAttrs (old: { langs = [ "en-US" "lt" ]; })) # Office suite
      iosevka-nerdfonts
      firefox-custom # Customized firefox derivation
      ((eww.overrideAttrs (old: rec {
        src = pkgs.fetchFromGitHub {
          owner = "elkowar";
          repo = "eww";
          rev = "106106ade31e7cc669f2ae53f24191cd0a683c39";
          sha256 = "sha256-VntDl7JaIfvn3pd+2uDocnXFRkPnQQbRkYDn4XWeC5o=";
        };
        cargoDeps = old.cargoDeps.overrideAttrs (_: {
          inherit src;
          outputHash = "sha256-+OJ1BC/+iKkoCK2/+xA26fG2XtcgKJMv4UHmhc9Yv9k=";
        });
      })).override { withWayland = true; }) # Desktop widgets
      gimp # Image manipulation program
      inter # UI typeface
      iosevka # Monospace programming typeface
      # kora-icon-theme # Applications icon theme
      liberation_ttf # Replacement fonts for TNR, Arial and Courier New
      quintom-cursor-theme # X Cursor theme
      source-han-sans # Japanese OpenType/CFF fonts
      meld # Visual diff and merge tool
      simple-scan # GNOME GUI scanner tool
    ];
  in
  shellPkgs ++ waylandPkgs ++ graphicalPkgs;

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

