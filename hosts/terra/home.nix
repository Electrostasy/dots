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

      # Celluloid has way too many associations with audio files, I need them to
      # be opened with Amberol instead.
      associations =
        let
          associate = desktop: mimeTypes:
            builtins.listToAttrs
              (builtins.map (mime: { name = mime; value = desktop; }) mimeTypes);
          mkAudioMimeType = builtins.map (x: "audio/" + x);
        in
          {
            added =
              associate
                "io.bassi.Amberol.desktop"
                (mkAudioMimeType [
                  "aac"
                  "ac3"
                  "flac"
                  "m4a"
                  "mp1"
                  "mp2"
                  "mp3"
                  "mpegurl"
                  "mpg"
                  "ogg"
                  "opus"
                  "x-wav"
                ]);

            removed =
              associate
                "io.github.celluloid_player.Celluloid.desktop"
                (mkAudioMimeType [
                  "mpeg"
                  "wav"
                  "x-aac"
                  "x-aiff"
                  "x-ape"
                  "x-flac"
                  "x-m4a"
                  "x-mp1"
                  "x-mp2"
                  "x-mp3"
                  "x-mpeg"
                  "x-mpegurl"
                  "x-mpg"
                  "x-pn-aiff"
                  "x-pn-au"
                  "x-pn-wav"
                  "x-speex"
                  "x-vorbis"
                  "x-vorbis+ogg"
                  "x-wavpack"
                ]);
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

      freerdp # xfreerdp
      neo
      nurl
      pastel
      youtube-dl

      ipafont
      liberation_ttf
    ];
  };
}

