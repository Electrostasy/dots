{
  home-manager.users.electro = { config, pkgs, lib, ... }: {
    imports = [
      ../../profiles/user/mpv
      ../../profiles/user/neovim
      ../../profiles/user/tealdeer
      ../../profiles/user/zathura
    ];

    home.stateVersion = "22.11";

    programs.mpv = {
      package = pkgs.celluloid;
      scripts = lib.mkForce [ ];
      config = {
        # Border is required for Celluloid's CSD to render.
        border = "yes";
        autofit-smaller = "1920x1080";
        cursor-autohide = "always";
      };
    };

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
        "application/pdf" = "org.pwmt.zathura.desktop";
      };
    };

    fonts.fontconfig.enable = true;

    home.packages = with pkgs; [
      f3d
      freecad
      prusa-slicer

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
      freerdp # xfreerdp
      magic-wormhole-rs
      neo
      nurl
      pastel
      smartmontools # smartctl
      tio
      youtube-dl

      ipafont
      liberation_ttf
    ];

    home.shellAliases = {
      wormhole = "${pkgs.magic-wormhole-rs.meta.mainProgram}";
    };
  };
}

