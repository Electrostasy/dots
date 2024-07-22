{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs.gnomeExtensions; [
    blur-my-shell
    desktop-cube
    native-window-placement
    panel-date-format
    tiling-assistant
  ];

  programs.dconf.profiles.user.databases = [{
    settings = with lib.gvariant; {
      "org/gnome/shell".enabled-extensions =
        builtins.map
          (x: x.extensionUuid)
          (lib.filter (p: p ? extensionUuid) config.environment.systemPackages)
        # For extensions packaged together with `gnome-shell-extensions`, but
        # that do not have an individual uuid and package entry listed in nixpkgs'
        # pkgs/desktops/gnome/extensions/extensionRenames.nix file:
        ++ [ "system-monitor@gnome-shell-extensions.gcampax.github.com" ];

      "org/gnome/shell/extensions/panel-date-format".format = "%Y-%m-%d %H:%M";

      "org/gnome/shell/extensions/desktop-cube" = {
        last-first-gap = false;
        window-parallax = 0.75;
        edge-switch-pressure = mkUint32 100;
        mouse-rotation-speed = 1.0;

        # These settings interfere with touchscreen gestures (specifically
        # 3 finger horizontal swipes for switching workspaces on the desktop
        # and 3 finger vertical swipes for overview). We can still use the panel.
        enable-desktop-dragging = false;
        enable-overview-dragging = false;
        enable-panel-dragging = true;
      };

      "org/gnome/shell/extensions/tiling-assistant" = {
        active-window-hint = mkUint32 0;
        restore-window = [ "<Super>r" ];
        tile-bottom-half = [ "<Super>s" ];
        tile-bottomleft-quarter = [ "<Alt><Super>a" ];
        tile-bottomright-quarter = [ "<Alt><Super>d" ];
        tile-left-half = [ "<Super>a" ];
        tile-maximize = [ "<Super>f" ];
        tile-right-half = [ "<Super>d" ];
        tile-top-half = [ "<Super>w" ];
        tile-topleft-quarter = [ "<Alt><Super>q" ];
        tile-topright-quarter = [ "<Alt><Super>e" ];
      };
    };
  }];
}
