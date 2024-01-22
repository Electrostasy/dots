{
  dbus,
  dbusSupport ? true,
  extraSessionCommands ? [],
  gdk-pixbuf,
  glib,
  gtk3,
  lib,
  makeWrapper,
  plugins ? [],
  symlinkJoin,
  wayfire,
  withGtkWrapper ? false,
  wrapGAppsHook,
  writeShellScriptBin,
}:

let
  pluginLibs = lib.makeSearchPath "lib/wayfire" plugins;
  pluginXmls = lib.makeSearchPath "share/wayfire/metadata" plugins;
  wrapperScript = writeShellScriptBin "wayfire" ''
    set -o errexit
    if [ ! "$_WAYFIRE_WRAPPER_ALREADY_EXECUTED" ]; then
      export XDG_CURRENT_DESKTOP=sway
      ${lib.concatStringsSep "\n" extraSessionCommands}
      export _WAYFIRE_WRAPPER_ALREADY_EXECUTED=1
    fi
    if [ "$DBUS_SESSION_BUS_ADDRESS" ]; then
      export DBUS_SESSION_BUS_ADDRESS
      exec ${wayfire}/bin/wayfire "$@"
    else
      exec ${lib.optionalString dbusSupport "${dbus}/bin/dbus-run-session"} ${wayfire}/bin/wayfire "$@"
    fi
  '';
in
symlinkJoin {
  name = "wayfire-${wayfire.version}-wrapped";
  paths = [ wrapperScript wayfire ];

  nativeBuildInputs = [ makeWrapper ] ++ (lib.optional withGtkWrapper wrapGAppsHook);
  buildInputs = lib.optionals withGtkWrapper [ gdk-pixbuf glib gtk3 ];

  dontWrapGApps = true;
  postBuild = ''
    ${lib.optionalString withGtkWrapper "gappsWrapperArgsHook"}

    wrapProgram $out/bin/wayfire \
      --suffix PATH : ${lib.escapeShellArg (lib.makeBinPath plugins)} \
      --suffix WAYFIRE_PLUGIN_PATH : ${lib.escapeShellArg pluginLibs} \
      --suffix WAYFIRE_PLUGIN_XML_PATH : ${lib.escapeShellArg pluginXmls} \
      ${lib.optionalString withGtkWrapper ''"''${gappsWrapperArgs[@]}"''}
  '';
}
