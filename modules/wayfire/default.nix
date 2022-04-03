{ config, pkgs, ... }:

{
  wayland.windowManager.wayfire = {
    enable = true;
    package = pkgs.wayfire-git;

    settings = {
      close_top_view = "<super> <shift> KEY_W";
      preferred_decoration_mode = "server";
      xwayland = true;

      plugins = [
        {
          package = pkgs.wayfirePlugins.firedecor;
          plugin = "firedecor";
          settings = {
            border_size = 8;
            active_border = [ 0.12 0.12 0.15 1.0 ];
            inactive_border = [ 0.12 0.12 0.15 1.0 ];
            outline_size = 4;
            active_outline = [ 0.176 0.31 0.4 1.0 ];
            inactive_outline = [ 0.086 0.086 0.114 1.0 ];
            corner_radius = 8;
            layout = "-";
          };
        }
        {
          # Allows using true fullscreen mode for windows, which
          # enables direct scanout in nested usecases like gamescope
          plugin = "wm-actions";
          settings.toggle_fullscreen = "<super> KEY_F11";
        }
        {
          plugin = "move";
          settings = {
            activate = "<super> BTN_LEFT";
            snap_threshold = 16;
            quarter_snap_threshold = 64;
          };
        }
        {
          plugin = "resize";
          settings = {
            activate = "<super> BTN_RIGHT";
          };
        }
        {
          plugin = "switcher";
          settings = {
            next_view = "<alt> KEY_TAB";
            prev_view = "<alt> <shift> KEY_TAB";
            speed = 350;
            view_thumbnail_scale = 1.0;
          };
        }
        {
          plugin = "scale";
          settings = {
            toggle = "<super> KEY_TAB";
            animation_transition_time = 350;
            interact = false;
            allow_zoom = false;
            middle_click_close = true;
            spacing = 50;
            inactive_alpha = 0.8;
            title_overlay = "mouse";
            title_font_size = 12;
            title_position = "bottom";
            bg_color = [ 0.1 0.1 0.1 0.9 ];
            text_color = [ 0.8 0.8 0.8 1.0 ];
          };
        }
        {
          plugin = "grid";
          settings = {
            duration = 250;
            type = "crossfade";
            restore = "<super> KEY_F";
            slot_c = "<super> <shift> KEY_F";
            slot_b = "<super> KEY_S";
            slot_t = "<super> KEY_W";
            slot_l = "<super> KEY_A";
            slot_r = "<super> KEY_D";
            slot_tl = "<super> <shift> KEY_Q";
            slot_tr = "<super> <shift> KEY_E";
            slot_bl = "<super> KEY_Q";
            slot_br = "<super> KEY_E";
          };
        }
        {
          plugin = "animate";
          settings = {
            close_animation = "zoom";
            open_animation = "zoom";
            zoom_duration = 250;
            zoom_enabled_for = "(type is \"toplevel\" | (type is \"x-or\" & focusable is true))";
            startup_duration = 1500;
          };
        }
        {
          plugin = "autostart";
          settings = {
            dbus = ''
              exec systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
              exec hash dbus-update-activation-environment 2>/dev/null && \
                dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
            '';
            screenshare = ''
              sleep 1 && (XDG_SESSION_TYPE=wayland XDG_CURRENT_DESKTOP=sway ${pkgs.xdg-desktop-portal}/libexec/xdg-desktop-portal --replace & ${pkgs.xdg-desktop-portal-wlr}/libexec/xdg-desktop-portal-wlr)
            '';
            idle = ''
              ${pkgs.swayidle}/bin/swayidle -w \
                timeout 600 '${pkgs.fish}/bin/fish -c ${./outputs.fish} --off' \
                resume '${pkgs.fish}/bin/fish -c ${./outputs.fish} --on'
            '';
            outputs = "${pkgs.kanshi}/bin/kanshi";
          };
        }
        {
          plugin = "command";
          settings = {
            binding_terminal = "<super> KEY_ENTER";
            command_terminal = "${pkgs.kitty}/bin/kitty";
            binding_launcher = "<super> KEY_SPACE";
            command_launcher = ''
              ${config.programs.rofi.finalPackage}/bin/rofi -show drun -config ${./rofi-drun.rasi}
            '';
            binding_screenshot = "<super> <shift> KEY_S";
            command_screenshot = "${pkgs.writeShellScriptBin "screenshot" ''
              # For some reason, if this command is not wrapped in a script, the command
              # silently fails when runs specifically from Wayfire and I have no idea why
              ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp -d -b '#16161daa' -c '#dcd7baff' -s '#00000000' -w 1)" - | ${pkgs.wl-clipboard}/bin/wl-copy -t image/png
            ''}/bin/screenshot";
          };
        }
        {
          plugin = "input";
          settings = {
            mouse_accel_profile = "flat";
            xkb_layout = "us,lt";
            xkb_model = "pc105";
            xkb_options = "grp:alt_shift_toggle";
          };
        }
      ];
    };
  };
}
