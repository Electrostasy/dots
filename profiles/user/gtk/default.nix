{ config, pkgs, ... }:

{
  gtk = {
    enable = true;

    theme = {
      package = pkgs.gnome-themes-extra;
      name = "Adwaita-dark";
    };
    gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
    gtk4.extraConfig = {
      # NOTE: doesn't work with libadwaita programs
      gtk-application-prefer-dark-theme = 1;
    };
  };
  home.pointerCursor.gtk.enable = true;
}
