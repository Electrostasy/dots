{ config, pkgs, lib, ... }:

{
  xdg.enable = true;
  home.file.".config/eww".source = ./eww;

  services.kanshi = {
    enable = true;

    profiles.default = {
      exec = "${pkgs.wlr-spanbg}/bin/wlr-spanbg \"$(find ~/Pictures -type f | shuf -n1)\"";
      outputs = [
        {
          criteria = "Acer Technologies XV273K 0x0000BBC4";
          status = "enable";
          mode = "3840x2160@119.910Hz";
          position = "0,1080";
          scale = 1.5;
        }
        {
          criteria = "BenQ Corporation BenQ XL2420T M3D05947SL0";
          status = "enable";
          mode = "1920x1080@119.982Hz";
          position = "320,0";
        }
        {
          criteria = "Goldstar Company Ltd LG FULL HD";
          status = "enable";
          mode = "1920x1080@74.973Hz";
          position = "2560,860";
          transform = "270";
        }
      ];
    };
  };


  home.pointerCursor = {
    package = pkgs.simp1e-cursor-theme.override {
      theme = {
        name = "Simp1e Kanagawa";
        shadow_opacity = 0.35;
        shadow = "#16161D";
        cursor_border = "#DCD7BA";
        default_cursor_bg = "#1F1F28";
        hand_bg = "#1F1F28";
        question_mark_bg = "#658594";
        question_mark_fg = "#1F1F28";
        plus_bg = "#76946A";
        plus_fg = "#1F1F28";
        link_bg = "#957FB8";
        link_fg = "#1F1F28";
        move_bg = "#FFA066";
        move_fg = "#1F1F28";
        context_menu_bg = "#7E9CD8";
        context_menu_fg = "#1F1F28";
        forbidden_bg = "#1F1F28";
        forbidden_fg = "#E82424";
        magnifier_bg = "#1F1F28";
        magnifier_fg = "#DCD7BA";
        skull_bg = "#1F1F28";
        skull_eye = "#DCD7BA";
        spinner_bg = "#1F1F28";
        spinner_fg1 = "#DCD7BA";
        spinner_fg2 = "#DCD7BA";
      };
    };
    name = "Simp1e-Kanagawa";
    size = 24;

    x11.enable = true;
    gtk.enable = true;
  };

  gtk = {
    enable = true;
    theme = {
      package = pkgs.gnome-themes-extra;
      name = "Adwaita-dark";
    };
    gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
  };

  home.packages = with pkgs; let
    iosevka-nerdfonts = nerdfonts-patch (iosevka.override {
      privateBuildPlan = {
        family = "Iosevka Custom";
        spacing = "normal";
        serifs = "sans";
        no-cv-ss = true;
        no-litigation = true;
      };
      set = "custom";
    });
    in [
    alsaUtils
    bottom # System resources monitor
    chafa # Image data terminal previewer
    du-dust # Disk usage visualizer
    eww-wayland # Desktop widgets
    f3d # 3D file format viewer
    ffmpeg
    fio # IO benchmark tool
    firefox-custom
    freecad
    gimp
    grim # Wayland compositor image grabber
    imagemagick
    inter # UI typeface
    iosevka-nerdfonts
    jq
    (imv.override { withWindowSystem = "wayland"; })
    keepassxc # Password manager
    liberation_ttf # Replacement fonts for TNR, Arial and Courier New
    (libreoffice.overrideAttrs (_: { langs = [ "en-US" "lt" ]; }))
    neofetch
    pastel # Generate, analyze, convert and manipulate colours
    rehex # Hex editor
    # rink # Unit-aware calculator/conversion tool
    ripgrep
    schildichat-desktop # Matrix chat client
    slurp # Wayland compositor region selector
    solvespace # Parametric 3D CAD
    source-han-sans # Japanese OpenType/CFF fonts
    super-slicer # 3D printer slicer software
    tealdeer # `tldr` alternative
    # (texlive.combine { inherit (texlive) scheme-minimal lithuanian hyphen-lithuanian collection-langenglish; })
    transmission-gtk # BitTorrent client
    wf-recorder # Record wayland displays
    wl-clipboard # `wl-{copy,paste}` clipboard utilities
    wlopm # Wayland output management
    xdg-utils # for `xdg-open`
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

    fish.functions = {
      reboot-windows = {
        description = "Reboot into Windows if it is present";
        body = ''
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
      };
      share-screen = {
        description = "Share a selected screen using v4l2";
        body = ''
          set -l intro 'Select a display to begin sharing to /dev/video0.\nOnce selected, "mpv --demuxer-lavf-format=video4linux2 av://v4l2:/dev/video0" to preview.'
          set -l command "echo $intro; wf-recorder --muxer=v4l2 --file=/dev/video0 -c rawvideo -o (slurp -o -f \"%o\") -x yuyv422"

          kitty fish -c "$command"
        '';
      };
    };

    git = {
      enable = true;
      userName = "Gediminas Valys";
      userEmail = "steamykins@gmail.com";
    };
  };
}

