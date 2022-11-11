{ pkgs, ... }:

{
  services.dbus.enable = true;

  xdg.portal.wlr = {
    enable = true;

    settings.screencast = {
      max_fps = 30;
      chooser_type = "simple";
      chooser_cmd = "${pkgs.slurp}/bin/slurp -f %o -or";
    };
  };
}
