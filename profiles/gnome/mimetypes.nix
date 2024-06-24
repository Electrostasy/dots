{ lib, ... }:

let
  # Turns `"program.desktop" = "mimetype"` into `"mimetype" = "program.desktop"`,
  # making it easier to associate a *.desktop with multiple mimetypes without
  # too much repetition.
  associate = { desktops, mimeTypes }:
    lib.listToAttrs (builtins.map (mime: { name = mime; value = desktops; }) mimeTypes);
in

{
  xdg.mime = {
    enable = true;

    # Handle other audio formats already specified as audio/x-* but
    # not audio/*, or as audio/* but not audio/x-*.
    addedAssociations = associate {
      desktops = "io.bassi.Amberol.desktop";
      mimeTypes = [
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
      ];
    };

    removedAssociations = lib.attrsets.mergeAttrsList [
      # Prefer to open images with Loupe instead of an image editor.
      (associate {
        desktops = "gimp.desktop";
        mimeTypes = [
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
        ];
      })
    ];
  };
}
