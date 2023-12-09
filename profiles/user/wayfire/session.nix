{ osConfig, pkgs, lib, ... }:

let
  variables = lib.concatStringsSep " " [
    "DISPLAY"
    "WAYLAND_DISPLAY"
    "XDG_CURRENT_DESKTOP"
    "XDG_SESSION_TYPE"
  ];

  update-environment = "exec ${pkgs.dbus}/bin/dbus-update-activation-environment";
  systemctl = "exec ${pkgs.systemd}/bin/systemctl --user";
in
{
  assertions = [
    { assertion = osConfig.services.dbus.enable;
      message = "services.dbus.enable must be set to true in NixOS config.";
    }
  ];

  home.sessionVariables = {
    # Programs may use this for WM/DE specific behavior.
    XDG_CURRENT_DESKTOP = "sway";

    # Programs may use this for Wayland detection.
    XDG_SESSION_TYPE = "wayland";
  };

  wayland.windowManager.wayfire.settings.plugins = [{
    plugin = "autostart";
    settings = {
      # We can use the `--systemd` flag to have DBus import the environment
      # variables into the systemd user session, but this does not seem to
      # actually work.
      a0001_dbus_env = "${update-environment} 2>/dev/null && ${update-environment} ${variables}";

      # Because DBus cannot import the variables into the systemd user session,
      # we explicitly import them here next.
      a0002_systemd_env = "${systemctl} import-environment ${variables}";

      # TODO: Stop wayfire-session.target when Wayfire closes, and unset all
      # set environment variables in the systemd user session.
      a0003_session = "${systemctl} start wayfire-session.target";
    };
  }];
}
