{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs.gnomeExtensions; [
    blur-my-shell
    desktop-cube
    native-window-placement
    panel-date-format
    tiling-shell
    unblank

    # Blur My Shell extension seems to be buggy regarding the panel when fractional
    # scaling is enabled - only part of the panel is blurred. Turning it on and
    # off again seems to fix it. Do that soon as the session starts.
    (pkgs.makeAutostartItem {
      name = "blur-my-shell-fix";
      package = pkgs.makeDesktopItem {
        name = "blur-my-shell-fix";
        desktopName = "Fix for Blur my Shell when used with fractional scaling";
        categories = [ "Utility" ];
        noDisplay = true;
        terminal = false;
        type = "Application";
        exec = lib.getExe (pkgs.writeShellApplication {
          name = "blur-my-shell-fix";
          runtimeInputs = [
            config.systemd.package
            pkgs.gnome-shell
            pkgs.jq
          ];

          text = ''
            function get_current_state() {
              busctl --user call \
                'org.gnome.Mutter.DisplayConfig' \
                '/org/gnome/Mutter/DisplayConfig' \
                'org.gnome.Mutter.DisplayConfig' \
                'GetCurrentState' -j
            }

            # Only run if any display has fractional scaling enabled.
            if [ "$(get_current_state | jq '.data[2] | map(fmod(.[2]; 1) | select(. != 0)) | length')" -ne '0' ]; then
              gnome-extensions disable 'blur-my-shell@aunetx'
              sleep 0.5 # wait a bit before re-enabling.
              gnome-extensions enable 'blur-my-shell@aunetx'
            fi
          '';
        });
      };
    })

    (pkgs.runCommandLocal "electrostasy-shell-theme" { } ''
      install -D ${./gnome-shell.css} $out/share/themes/electrostasy/gnome-shell/gnome-shell.css
    '')
  ];

  # TODO: Refactor to `systemd.user.tmpfiles.settings` when
  # https://github.com/NixOS/nixpkgs/pull/317383 is merged.
  systemd.user.tmpfiles.rules = [
    "L+ %h/.config/gtk-4.0/gtk.css - - - - ${./gtk.css}"
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
        ++ [
          "system-monitor@gnome-shell-extensions.gcampax.github.com"
          "user-theme@gnome-shell-extensions.gcampax.github.com"
        ];

      "org/gnome/shell/extensions/user-theme".name = "electrostasy";

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

      "org/gnome/shell/extensions/panel-date-format".format = "%Y-%m-%d %H:%M";

      "org/gnome/shell/extensions/tilingshell" = {
        enable-blur-snap-assistant = true;
        enable-snap-assist = false;
        inner-gaps = mkUint32 0;
        outer-gaps = mkUint32 0;

        # Default to the horizontal split, override in other modules. This is
        # because tilingshell does not identify a "main output" (which isn't
        # really a thing in wayland anyway), so the leftmost output is the
        # first one in the list.
        selected-layouts = [ "1/1 H-Split" ];

        layouts-json = builtins.toJSON [
          {
            id = "1/1 H-Split";
            tiles = [
              { groups = [ 1 ]; height = 1; width = 0.5; x = 0; y = 0; }
              { groups = [ 1 ]; height = 1; width = 0.5; x = 0.5; y = 0; }
            ];
          }
          {
            id = "1/1 V-Split";
            tiles = [
              { groups = [ 1 ]; height = 0.5; width = 1; x = 0; y = 0; }
              { groups = [ 1 ]; height = 0.5; width = 1; x = 0; y = 0.5; }
            ];
          }
          {
            id = "1/2 H-Split";
            tiles = [
              { groups = [ 1 ]; height = 1; width = 0.33; x = 0; y = 0; }
              { groups = [ 1 ]; height = 1; width = 0.67; x = 0.33; y = 0; }
            ];
          }
          {
            id = "2/1 H-Split";
            tiles = [
              { groups = [ 1 ]; height = 1; width = 0.67; x = 0; y = 0; }
              { groups = [ 1 ]; height = 1; width = 0.33; x = 0.67; y = 0; }
            ];
          }
          {
            id = "1/1/1 H-Split";
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
