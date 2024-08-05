{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs.gnomeExtensions; [
    blur-my-shell
    desktop-cube
    fullscreen-to-empty-workspace
    native-window-placement
    panel-date-format
    tiling-shell
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

      "org/gnome/shell/extensions/fullscreen-to-empty-workspace".move-window-when-maximized = false;

      "org/gnome/shell/extensions/panel-date-format".format = "%Y-%m-%d %H:%M";

      "org/gnome/shell/extensions/tilingshell" = {
        enable-blur-snap-assistant = true;
        enable-snap-assist = false;
        inner-gaps = mkUint32 0;
        outer-gaps = mkUint32 0;
        selected-layouts = [ "Dual Even Split" ];
        layouts-json = builtins.toJSON [
          {
            id = "Dual Little-Big Split";
            tiles = [
              { groups = [ 1 ]; height = 1; width = 0.33; x = 0; y = 0; }
              { groups = [ 1 ]; height = 1; width = 0.67; x = 0.33; y = 0; }
            ];
          }
          {
            id = "Dual Big-Little Split";
            tiles = [
              { groups = [ 1 ]; height = 1; width = 0.67; x = 0; y = 0; }
              { groups = [ 1 ]; height = 1; width = 0.33; x = 0.67; y = 0; }
            ];
          }
          {
            id = "Dual Even Split";
            tiles = [
              { groups = [ 1 ]; height = 1; width = 0.5; x = 0; y = 0; }
              { groups = [ 1 ]; height = 1; width = 0.5; x = 0.5; y = 0; }
            ];
          }
          {
            id = "Triple Even Split";
            tiles = [
              { groups = [ 1 ]; height = 1; width = 0.333333; x = 0; y = 0; }
              { groups = [ 1 ]; height = 1; width = 0.333333; x = 0.333333; y = 0; }
              { groups = [ 1 ]; height = 1; width = 0.333333; x = 0.666666; y = 0; }
            ];
          }
        ];
      };
    };
  }];
}
