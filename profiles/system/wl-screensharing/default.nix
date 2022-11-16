{ pkgs, ... }:

{
  services.dbus.enable = true;

  # Enables the xdg-desktop-portal-wlr Screenshot and ScreenCast portals
  # for xdg-desktop-portal and wlroots-based Wayland compositors.
  xdg.portal.wlr = {
    enable = true;

    settings.screencast = {
      max_fps = 60;
      chooser_type = "simple";
      chooser_cmd = "${pkgs.slurp}/bin/slurp -f %o -or";
    };
  };
}
