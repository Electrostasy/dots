{ config, pkgs, ... }:

{
  xdg.enable = true;

  wayland.windowManager.wayfire.settings.plugins = [
    { plugin = "output:DP-1";
      settings = {
        mode = "3840x2160@119910";
        position = "0,250";
        scale = 1.5;
      };
    }
    { plugin = "output:DP-2";
      settings.mode = "off";
    }
    { plugin = "output:HDMI-A-1";
      settings = {
        mode = "1920x1080@74973";
        position = "2560,0";
        transform = 270;
      };
    }
  ];

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
    (aspellWithDicts (ds: with ds; [ en lt ]))
    chafa # Image data terminal previewer
    cura
    # dfeet # graphical dbus monitor
    du-dust
    element-desktop
    f3d
    ffmpeg
    fio
    firefox-custom
    freecad
    gimp
    glib # for gdbus
    grim
    imagemagick
    (imv.override { withWindowSystem = "wayland"; })
    inter # UI typeface
    iosevka-nerdfonts
    keepassxc
    liberation_ttf # Replacement fonts for TNR, Arial and Courier New
    (libreoffice.overrideAttrs (_: { langs = [ "en-US" "lt" ]; }))
    pastel
    slurp
    solvespace
    source-han-sans # Required for rendering Japanese font
    super-slicer
    transmission-gtk
    wf-recorder
    wl-clipboard
    wlopm
    xdg-utils
    xplr
    youtube-dl
  ];

  fonts.fontconfig.enable = true;

  programs = {
    zathura = {
      enable = true;

      options = {
        default-bg = "#1F1F28";
        default-fg = "#DCD7BA";
        recolor = true;
      };
    };

    rofi = {
      enable = true;
      package = pkgs.rofi-wayland;

      terminal = "${pkgs.kitty}/bin/kitty";
      extraConfig = {
        modi = "drun,run";
        kb-primary-paste = "Control+V";
        kb-secondary-paste = "Control+v";
      };
    };

    eww = {
      enable = true;
      package = pkgs.eww-wayland;

      configDir = ./eww;
    };

    bottom = {
      enable = true;

      settings.flags.tree = true;
    };

    tealdeer = {
      enable = true;

      settings = {
        display = {
          use_pager = false;
          compact = false;
        };

        updates = {
          auto_update = true;
          auto_update_interval_hours = 720;
        };
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
      extraConfig = {
        # https://github.com/NixOS/nixpkgs/issues/169193#issuecomment-1103816735
        safe.directory = "/etc/nixos";
      };
    };
  };
}

