{ config, pkgs, ... }:

{
  home.stateVersion = "22.11";

  xdg.userDirs = {
    enable = true;

    desktop = null; # unused
    documents = "${config.home.homeDirectory}/documents";
    download = "${config.home.homeDirectory}/downloads";
    music = "${config.home.homeDirectory}/music";
    pictures = "${config.home.homeDirectory}/pictures";
    publicShare = null; # unused
    templates = null; # unused
    videos = "${config.home.homeDirectory}/videos";
  };

  xdg.mimeApps = {
    enable = true;

    # Removed/added associations are not respected for some arcane reason,
    # set default applications instead.
    defaultApplications = {
      "image/gif" = "imv.desktop";
      "image/jpeg" = "imv.desktop";
      "image/png" = "imv.desktop";
      "image/webp" = "imv.desktop";
    };
  };

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
    { plugin = "autostart";
      settings.wallpapers = "${pkgs.wlr-spanbg}/bin/wlr-spanbg \"$(find ~/pictures -type f | shuf -n1)\"";
    }
  ];

  home.packages = with pkgs; [
    # 3D printing/CAD packages
    cura
    f3d # 3D file viewer (doesn't support *.stl)
    freecad
    fstl # 3D file viewer (specifically for *.stl)
    solvespace
    super-slicer

    # Desktop programs
    element-desktop
    firefox-custom
    gimp
    imv
    keepassxc
    libreoffice
    transmission-qt
    xdg-utils

    # Music
    mpc-cli
    projectm

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
    liberation_ttf # Replacement fonts for TNR, Arial and Courier New
    source-han-sans # Required for rendering Japanese font
  ];

  programs.bottom = {
    enable = true;

    settings.flags.tree = true;
  };
}

