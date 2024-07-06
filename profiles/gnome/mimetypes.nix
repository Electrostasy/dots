{ config, lib, ... }:

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

    defaultApplications = lib.attrsets.mergeAttrsList [
      {
        "text/plain" = lib.mkIf config.programs.neovim.enable "nvim.desktop";
        "application/pdf" = "org.gnome.Papers.desktop";
      }

      # Prefer to open images in Loupe instead of an image editor.
      (associate {
        desktops = "org.gnome.Loupe.desktop";
        mimeTypes = [
          "image/avif"
          "image/bmp"
          "image/gif"
          "image/heic"
          "image/jpeg"
          "image/jxl"
          "image/png"
          "image/svg+xml"
          "image/svg+xml-compressed"
          "image/tiff"
          "image/vnd.microsoft.icon"
          "image/vnd-ms.dds"
          "image/vnd.radiance"
          "image/webp"
          "image/x-dds"
          "image/x-exr"
          "image/x-portable-anymap"
          "image/x-portable-bitmap"
          "image/x-portable-graymap"
          "image/x-portable-pixmap"
          "image/x-qoi"
          "image/x-tga"
        ];
      })

      # Prefer to open 3D models in Exhibit instead of Prusa Slicer.
      (associate {
        desktops = "io.github.nokse22.Exhibit.desktop";
        mimeTypes = [
          "application/dicom"
          "application/vnd.3ds"
          "application/vnd.brep"
          "application/vnd.dae"
          "application/vnd.exodus"
          "application/vnd.fbx"
          "application/vnd.mhd"
          "application/vnd.nrrd"
          "application/vnd.off"
          "application/vnd.ply"
          "application/vnd.pts"
          "application/vnd.splat"
          "application/vnd.step"
          "application/vnd.vti"
          "application/vnd.vtk"
          "application/vnd.vtm"
          "application/vnd.vtp"
          "application/vnd.vtr"
          "application/vnd.vts"
          "application/vnd.vtu"
          "application/vnd.x"
          "application/x-tgif"
          "image/vnd.dxf"
          "model/3mf"
          "model/gltf+json"
          "model/gltf-binary"
          "model/gltf-json"
          "model/iges"
          "model/obj"
          "model/step"
          "model/stl"
          "model/x-other"
        ];
      })
    ];

    addedAssociations = lib.attrsets.mergeAttrsList [
      # Handle other audio formats already specified as audio/x-* but not audio/*,
      # or as audio/* but not audio/x-*.
      (associate {
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
      })

      # f3d's mime type associations not present in Exhibit's.
      (associate {
        desktops = "io.github.nokse22.Exhibit.desktop";
        mimeTypes = [
          "application/dicom"
          "application/vnd.3ds"
          "application/vnd.brep"
          "application/vnd.dae"
          "application/vnd.exodus"
          "application/vnd.fbx"
          "application/vnd.mhd"
          "application/vnd.nrrd"
          "application/vnd.off"
          "application/vnd.ply"
          "application/vnd.pts"
          "application/vnd.splat"
          "application/vnd.step"
          "application/vnd.vti"
          "application/vnd.vtk"
          "application/vnd.vtm"
          "application/vnd.vtp"
          "application/vnd.vtr"
          "application/vnd.vts"
          "application/vnd.vtu"
          "application/vnd.x"
          "application/x-tgif"
          "image/vnd.dxf"
          "model/gltf+json"
        ];
      })
    ];

    removedAssociations = lib.attrsets.mergeAttrsList [
      # These have too many false positives or are unnecessary.
      (associate {
        desktops = "io.github.nokse22.Exhibit.desktop";
        mimeTypes = [
          "application/gml+xml"
          "application/octet-stream"
          "application/prs.wavefront-obj"
          "application/vnd.ms-3mfdocument"
          "image/tiff"
          "image/vnd.dxf"
          "image/x-3ds"
          "text/plain"
          "text/vnd.abc"
        ];
      })
    ];
  };
}
