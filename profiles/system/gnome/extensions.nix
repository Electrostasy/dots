{ pkgs, lib, ... }:

let
  gnomeShellExtensions = with pkgs.gnomeExtensions; [
    blur-my-shell
    dash-to-panel
    desktop-cube
    native-window-placement
    panel-date-format
    tiling-assistant
    tophat
  ];
in

{
  environment = {
    # Needed for gnomeExtensions.tophat + GI_TYPELIB_PATH as per issue:
    # https://github.com/fflewddur/tophat/issues/106#issuecomment-1848319826
    variables.GI_TYPELIB_PATH = "/run/current-system/sw/lib/girepository-1.0";
    systemPackages = [ pkgs.libgtop ] ++ gnomeShellExtensions;
  };

  programs.dconf.profiles.user.databases = [{
    settings = with lib.gvariant; {
      "org/gnome/shell".enabled-extensions =
        builtins.map
          (x: x.extensionUuid)
          gnomeShellExtensions;

      "org/gnome/shell/extensions/panel-date-format".format = "%Y-%m-%d %H:%M";

      "org/gnome/shell/extensions/dash-to-panel" = {
        # Even when we are not using multiple panels on multiple monitors,
        # the extension still creates them in the config, so we set the same
        # configuration for each (up to 2 monitors).
        panel-positions = builtins.toJSON (lib.genAttrs [ "0" "1" ] (x: "TOP"));
        panel-sizes = builtins.toJSON (lib.genAttrs [ "0" "1" ] (x: 32));
        panel-element-positions = builtins.toJSON (lib.genAttrs [ "0" "1" ] (x: [
          { element = "showAppsButton"; visible = false; position = "stackedTL"; }
          { element = "activitiesButton"; visible = true; position = "stackedTL"; }
          { element = "dateMenu"; visible = true; position = "stackedTL"; }
          { element = "taskbar"; visible = true; position = "centerMonitor"; }
          { element = "leftBox"; visible = true; position = "stackedBR"; }
          { element = "rightBox"; visible = true; position = "stackedTL"; }
          { element = "centerBox"; visible = false; position = "centered"; }
          { element = "systemMenu"; visible = true; position = "stackedBR"; }
          { element = "desktopButton"; visible = false; position = "stackedBR"; }
        ]));
        multi-monitors = false;
        focus-highlight-dominant = true;
        dot-size = mkInt32 2;
        dot-position = "TOP";
        dot-color-dominant = true;
        appicon-padding = mkInt32 2;
        appicon-margin = mkInt32 2;
        trans-use-custom-opacity = true;
        trans-panel-opacity = 0.25;
        show-favorites = false;
        group-apps = false;
        isolate-workspaces = true;
        hide-overview-on-startup = true;
        stockgs-keep-dash = true;
      };

      "org/gnome/shell/extensions/blur-my-shell".color-and-noise = false;
      "org/gnome/shell/extensions/blur-my-shell/applications".blur = false;
      "org/gnome/shell/extensions/blur-my-shell/panel".override-background = false;

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

      "org/gnome/shell/extensions/tophat" = {
        cpu-display = "both";
        mem-display = "both";
        show-disk = false;
      };
    };
  }];
}
