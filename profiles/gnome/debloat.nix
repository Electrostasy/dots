{ pkgs, lib, ... }:

{
  services = {
    # Due to the way desktop configuration works in Nixpkgs, we have to install
    # an X server even if we only use Wayland.
    xserver = {
      enable = true;

      # We can exclude these packages without breaking X in gnome-shell, even if
      # I almost never use it.
      excludePackages = [ pkgs.xterm ] ++ (with pkgs.xorg; [
        iceauth
        xauth
        xf86inputevdev
        xinput
        xlsclients
        xorgserver
        xprop
        xrandr
        xrdb
        xset
        xsetroot
      ]);
    };

    # Disable unused GNOME module features.
    avahi.enable = false;
    dleyna-renderer.enable = false;
    dleyna-server.enable = false;
    hardware.bolt.enable = false;
    gnome = {
      evolution-data-server.enable = lib.mkForce false;
      gnome-browser-connector.enable = false;
      gnome-initial-setup.enable = false;
      gnome-online-accounts.enable = lib.mkForce false;
      gnome-online-miners.enable = lib.mkForce false;
      gnome-user-share.enable = false;
      rygel.enable = false;
    };
  };

  # Most of these are optional programs added by services.gnome.core-services
  # and etc., but the module sets other useful options so it is better to
  # exclude these instead of disabling the module.
  environment.gnome.excludePackages = [
    # pkgs.glib # for xdg-* commands to work correctly on gnome, `gio` is needed.
    pkgs.baobab
    pkgs.epiphany
    pkgs.evince
    pkgs.geary
    pkgs.gnome-connections
    pkgs.gnome-font-viewer
    pkgs.gnome-system-monitor
    pkgs.gnome-text-editor
    pkgs.gnome-themes-extra
    pkgs.gnome-tour
    pkgs.gnome-user-docs
    pkgs.gnome.gnome-backgrounds
    pkgs.gnome.gnome-bluetooth
    pkgs.gnome.gnome-characters
    pkgs.gnome.gnome-clocks
    pkgs.gnome.gnome-color-manager
    pkgs.gnome.gnome-contacts
    pkgs.gnome.gnome-logs
    pkgs.gnome.gnome-music
    pkgs.orca
    pkgs.simple-scan
    pkgs.totem
    pkgs.yelp
  ];
}
