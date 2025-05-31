{ pkgs, lib, ... }:

{
  services = {
    avahi.enable = false;
    dleyna.enable = false;
    hardware.bolt.enable = false;
    gnome = {
      evolution-data-server.enable = lib.mkForce false;
      gnome-browser-connector.enable = false;
      gnome-initial-setup.enable = false;
      gnome-online-accounts.enable = lib.mkForce false;
      gnome-user-share.enable = false;
      rygel.enable = false;
    };
  };

  # Most of these are optional programs added by services.gnome.core-services
  # and etc., but the module sets other useful options so it is better to
  # exclude these instead of disabling the module.
  environment.gnome.excludePackages = [
    # For xdg-* commands to work correctly on gnome, `gio` is needed, provided
    # by glib:
    # pkgs.glib

    # https://gitlab.gnome.org/GNOME/gnome-shell-extensions/-/issues/512
    # For `system-monitor` shell extension to work correctly, the GNOME Core
    # program `system-monitor` is required:
    # pkgs.gnome-system-monitor

    pkgs.adwaita-fonts
    pkgs.baobab
    pkgs.decibels
    pkgs.epiphany
    pkgs.evince
    pkgs.geary
    pkgs.gnome-backgrounds
    pkgs.gnome-bluetooth
    pkgs.gnome-characters
    pkgs.gnome-clocks
    pkgs.gnome-color-manager
    pkgs.gnome-connections
    pkgs.gnome-console
    pkgs.gnome-contacts
    pkgs.gnome-font-viewer
    pkgs.gnome-logs
    pkgs.gnome-music
    pkgs.gnome-text-editor
    pkgs.gnome-themes-extra
    pkgs.gnome-tour
    pkgs.gnome-user-docs
    pkgs.orca
    pkgs.simple-scan
    pkgs.totem
    pkgs.yelp
  ];
}
