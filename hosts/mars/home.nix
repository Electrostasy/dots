{ pkgs, ... }:

{
  xdg.enable = true;
  fonts.fontconfig.enable = true;

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

  home.packages = with pkgs; [
    # 3D printing/CAD packages
    cura
    f3d
    freecad
    solvespace
    super-slicer

    # Desktop programs
    element-desktop
    firefox-custom
    gimp
    (imv.override { withWindowSystem = "wayland"; })
    keepassxc
    (libreoffice.overrideAttrs (_: { langs = [ "en-US" "lt" ]; }))
    transmission-gtk
    xdg-utils

    # CLI utilities
    chafa
    du-dust
    ffmpeg
    fio
    imagemagick
    pastel
    xplr
    youtube-dl

    # Fonts
    inter
    iosevka-nerdfonts
    liberation_ttf # Replacement fonts for TNR, Arial and Courier New
    source-han-sans # Required for rendering Japanese font
  ];

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
  };
}

