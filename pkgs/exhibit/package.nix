{ python3Packages
, fetchFromGitHub
, appstream-glib
, desktop-file-utils
, gobject-introspection
, meson
, ninja
, pkg-config
, wrapGAppsHook4
, vtk_9
, f3d
, libadwaita
, lib
}:

let
  vtk_9_external = vtk_9.overrideAttrs (oldAttrs: {
    cmakeFlags = oldAttrs.cmakeFlags ++ [
      "-DVTK_OPENGL_HAS_EGL=ON"
      "-DVTK_MODULE_ENABLE_VTK_RenderingExternal=YES"
    ];
  });

  f3d_external = (f3d.override { vtk_9 = vtk_9_external; }).overrideAttrs (oldAttrs: {
    nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
      python3Packages.wrapPython
      python3Packages.pybind11
    ];

    cmakeFlags = oldAttrs.cmakeFlags ++ [
      "-DF3D_MODULE_EXTERNAL_RENDERING:BOOL=ON"
      "-DF3D_BINDINGS_PYTHON:BOOL=ON"
    ];
  });
in

python3Packages.buildPythonApplication {
  pname = "exhibit";
  version = "1.2.0";
  format = "other";

  src = fetchFromGitHub {
    owner = "Nokse22";
    repo = "Exhibit";
    rev = "v1.2.0";
    hash = "sha256-yNS6q7XbWda2+so9QRS/c4uYaVPo7b4JCite5nzc3Eo=";
  };

  nativeBuildInputs = [
    appstream-glib
    desktop-file-utils
    gobject-introspection
    meson
    ninja
    pkg-config
    wrapGAppsHook4
  ];

  buildInputs = [
    libadwaita
  ];

  dependencies = [
    f3d_external
    python3Packages.pygobject3
  ];

  meta = {
    description = "3D model viewer for the GNOME desktop powered by f3d";
    homepage = "https://github.com/Nokse22/Exhibit";
    mainProgram = "exhibit";
    license = lib.licenses.gpl3Plus;
  };
}
