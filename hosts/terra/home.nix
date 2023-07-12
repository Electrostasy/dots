{
  home-manager.users.electro = { config, pkgs, ... }: {
    imports = [
      ../../profiles/user/kitty
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
      { plugin = "command";
        settings = {
          # Switch between scaled and unscaled, shifting the position of the
          # outputs accordingly.
          binding_toggle_scale = "<super> <alt> KEY_GRAVE";
          command_toggle_scale = toString (pkgs.writeShellScript "toggle_scale.sh" ''
            file="$XDG_RUNTIME_DIR/toggle_scale"
            if [[ -e "$file" ]]; then
              ${pkgs.wlr-randr}/bin/wlr-randr --output DP-1 --pos 0,250 --scale 1.5
              ${pkgs.wlr-randr}/bin/wlr-randr --output HDMI-A-1 --pos 2560,0
              rm "$file"
            else
              ${pkgs.wlr-randr}/bin/wlr-randr --output DP-1 --pos 0,0 --scale 1.0
              ${pkgs.wlr-randr}/bin/wlr-randr --output HDMI-A-1 --pos 3840,120
              touch "$file"
            fi
          '');
        };
      }
      { plugin = "autostart";
        settings.wallpaper = toString (pkgs.writeShellScript "pick_wallpaper.sh" ''
          wallpaper="$(find ~/pictures/wallpapers -type f | shuf -n 1)"
          ${pkgs.wlr-spanbg}/bin/wlr-spanbg "$wallpaper"
        '');
      }
    ];

    home.packages = with pkgs; [
      f3d
      prusa-slicer
      solvespace

      gimp
      imv
      keepassxc
      libreoffice-fresh
      qpwgraph
      spek
      xdg-utils

      aria2
      bitwise
      detox
      dua
      e2fsprogs # badblocks
      fio
      freerdp # wlfreerdp
      magic-wormhole-rs
      neo
      nurl
      pastel
      qr
      smartmontools # smartctl
      xplr
      youtube-dl

      ipafont
      liberation_ttf
    ];

    home.shellAliases = {
      wormhole = "${pkgs.magic-wormhole-rs.meta.mainProgram}";
    };
  };
}

