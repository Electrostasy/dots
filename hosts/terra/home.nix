{
  home-manager.users.electro = { config, pkgs, lib, ... }: {
    imports = [
      ../../profiles/user/mpv
      ../../profiles/user/neovim
      ../../profiles/user/tealdeer
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

    xdg.mimeApps = {
      enable = true;

      defaultApplications = {
        "application/pdf" = "org.gnome.Evince.desktop";
      };

      associations =
        let
          associate = desktop: mimeTypes:
            builtins.listToAttrs
              (builtins.map (mime: { name = mime; value = desktop; }) mimeTypes);
        in
          {
            added =
              # Handle other audio formats already specified as audio/x-* but
              # not audio/*, or as audio/* but not audio/x-*.
              (associate "io.bassi.Amberol.desktop" [
                "audio/aac"
                "audio/ac3"
                "audio/flac"
                "audio/m4a"
                "audio/mp1"
                "audio/mp2"
                "audio/mp3"
                "audio/mpegurl"
                "audio/mpg"
                "audio/ogg"
                "audio/opus"
                "audio/x-wav"
              ]);

            removed =
              # Celluloid has way too many associations with audio files for
              # a video player.
              (associate "io.github.celluloid_player.Celluloid.desktop" [
                "audio/mpeg"
                "audio/wav"
                "audio/x-aac"
                "audio/x-aiff"
                "audio/x-ape"
                "audio/x-flac"
                "audio/x-m4a"
                "audio/x-mp1"
                "audio/x-mp2"
                "audio/x-mp3"
                "audio/x-mpeg"
                "audio/x-mpegurl"
                "audio/x-mpg"
                "audio/x-pn-aiff"
                "audio/x-pn-au"
                "audio/x-pn-wav"
                "audio/x-speex"
                "audio/x-vorbis"
                "audio/x-vorbis+ogg"
                "audio/x-wavpack"
              ])
              //
              # Prefer to open images with Loupe instead of an image editor.
              (associate "gimp.desktop" [
                "image/avif"
                "image/bmp"
                "image/gif"
                "image/heic"
                "image/heif"
                "image/jpeg"
                "image/jxl"
                "image/png"
                "image/svg+xml"
                "image/tiff"
                "image/webp"
                "image/x-exr"
                "image/x-portable-anymap"
                "image/x-portable-bitmap"
                "image/x-portable-graymap"
                "image/x-portable-pixmap"
                "image/x-tga"
                "image/x-webp"
              ]);
          };
    };

    fonts.fontconfig.enable = true;

    home.packages = with pkgs; [
      f3d
      freecad
      prusa-slicer

      freerdp # xfreerdp
      gimp
      keepassxc
      libreoffice-fresh
      neo
      nurl
      pastel
      pt-p300bt-labelmaker
      qpwgraph
      spek
      xdg-utils
      youtube-dl

      ipafont
      liberation_ttf
    ];
  };
}

