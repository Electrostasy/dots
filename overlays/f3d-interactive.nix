final: prev: {
  # Add this F3D to `environment.systemPackages` and its mimetypes and
  # thumbnailers will be picked up if your system is set up for it, i.e. the
  # following configuration is present (desktop modules usually set it):
  # {
  #   xdg.mime.enable = true;
  #   environment.pathsToLink = [ "/share/thumbnailers" ];
  # }
  f3d = prev.f3d.overrideAttrs (oldAttrs: {
    cmakeFlags = (oldAttrs.cmakeFlags or []) ++ [
      # This will set configuration directory to $out/share/f3d/configs
      # in F3D's configuration search path (see postInstall).
      "-DF3D_LINUX_INSTALL_DEFAULT_CONFIGURATION_FILE_IN_PREFIX=ON"
    ];

    # By default, configuration (including thumbnailer config) files and
    # mimetypes are not installed.
    postInstall = ''
      cmake --install . --prefix "$out" --component configuration
      cmake --install . --prefix "$out" --component mimetypes
    '';
  });
}
