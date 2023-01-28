{
  home-manager.users.electro = { config, pkgs, ... }: {
    imports = [
      ../../profiles/user/fish
      ../../profiles/user/kitty
      ../../profiles/user/lsd
      ../../profiles/user/mpv
      ../../profiles/user/neovim
      ../../profiles/user/tealdeer
      ../../profiles/user/wayfire
      ../../profiles/user/zathura
    ];

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
      { plugin = "output:HDMI-A-1";
        settings = {
          mode = "1920x1080@74973";
          position = "2560,0";
          transform = 270;
        };
      }
      { plugin = "autostart";
        settings = {
          wallpapers = "${pkgs.wlr-spanbg}/bin/wlr-spanbg $(find ~/pictures/wallpapers -type f | shuf -n1)";
          volume = "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 100%";
        };
      }
    ];

    home.packages = with pkgs; [
      cura
      prusa-slicer
      super-slicer
      f3d
      fstl
      solvespace

      firefox-custom
      gimp
      imv
      keepassxc
      # Wait for https://github.com/NixOS/nixpkgs/pull/212583
      # to hit nixos-unstable, broken build.
      # libreoffice
      qpwgraph
      spek
      xdg-utils

      aria2
      bitwise
      detox
      dua
      e2fsprogs # badblocks
      fio
      magic-wormhole
      neo
      nix-prefetch
      pastel
      smartmontools # smartctl
      vimv-rs
      xplr
      youtube-dl

      ipafont
      liberation_ttf
    ];

    programs.bottom = {
      enable = true;

      settings.flags.tree = true;
    };
  };
}

