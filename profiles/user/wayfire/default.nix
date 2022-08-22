{ config, pkgs, lib, ... }:

{
  home.pointerCursor = {
    package = pkgs.simp1e-cursor-theme.override {
      theme = {
        name = "Simp1e Kanagawa";
        shadow_opacity = 0.35;
        shadow = "#16161D";
        cursor_border = "#DCD7BA";
        default_cursor_bg = "#1F1F28";
        hand_bg = "#1F1F28";
        question_mark_bg = "#658594";
        question_mark_fg = "#1F1F28";
        plus_bg = "#76946A";
        plus_fg = "#1F1F28";
        link_bg = "#957FB8";
        link_fg = "#1F1F28";
        move_bg = "#FFA066";
        move_fg = "#1F1F28";
        context_menu_bg = "#7E9CD8";
        context_menu_fg = "#1F1F28";
        forbidden_bg = "#1F1F28";
        forbidden_fg = "#E82424";
        magnifier_bg = "#1F1F28";
        magnifier_fg = "#DCD7BA";
        skull_bg = "#1F1F28";
        skull_eye = "#DCD7BA";
        spinner_bg = "#1F1F28";
        spinner_fg1 = "#DCD7BA";
        spinner_fg2 = "#DCD7BA";
      };
    };
    name = "Simp1e-Kanagawa";
    size = 24;

    x11.enable = true;
  };

  home.packages = with pkgs; [
    # Wayland-specific packages
    grim
    slurp
    wf-recorder
    wl-clipboard
    wlopm

    # DBus utilities
    # dfeet # graphical dbus monitor
    glib # for gdbus
  ];

  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;

    terminal = "${pkgs.kitty}/bin/kitty";
    extraConfig = {
      modi = "drun,run";
      kb-primary-paste = "Control+V";
      kb-secondary-paste = "Control+v";
    };
  };

  wayland.windowManager.wayfire = {
    enable = true;
    package = pkgs.wayfire-git;

    withGtkWrapper = true;
    extraSessionCommands = [
      "export NIXOS_OZONE_WL=1"

      # Make Wayfire aware of gsettings schemas
      "export XDG_DATA_DIRS=${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:$XDG_DATA_DIRS"
      # Add gsettings schema from dbus-interface plugin
      "export XDG_DATA_DIRS=${pkgs.wayfirePlugins.dbus-interface}/share/gsettings-schemas/${pkgs.wayfirePlugins.dbus-interface.name}:$XDG_DATA_DIRS"
    ];

    settings = {
      close_top_view = "<super> <shift> KEY_W";
      preferred_decoration_mode = "server";
      xwayland = true;
      vheight = 3;
      vwidth = 3;

      plugins = [
        { package = pkgs.wayfirePlugins.dbus-interface; plugin = "dbus_interface"; }
        { package = pkgs.wayfirePlugins.plugins-extra; plugin = "glib-main-loop"; }

        { plugin = "move"; settings.activate = "<super> BTN_LEFT"; }
        { plugin = "place"; settings.mode = "cascade"; }
        { plugin = "resize"; settings.activate = "<super> BTN_RIGHT"; }
        { plugin = "wm-actions"; settings.toggle_fullscreen = "<super> KEY_F11"; }

        { package = pkgs.wayfirePlugins.shadows;
          plugin = "winshadows";
          settings = {
            clip_shadow_inside = false;
            horizontal_offset = 8;
            include_undecorated_views = true;
            shadow_color = "#000000FF";
            shadow_radius = 64;
            vertical_offset = 8;
          };
        }
        { package = pkgs.wayfirePlugins.firedecor;
          plugin = "firedecor";
          settings = {
            active_border = [ 0.121569 0.121569 0.156863 1.000000 ];
            active_outline = [ 0.176471 0.309804 0.403922 1.000000 ];
            border_size = 8;
            corner_radius = 8;
            inactive_border = [ 0.121569 0.121569 0.156863 1.000000 ];
            inactive_outline = [ 0.133333 0.196078 0.286275 1.000000 ];
            layout = "-";
            outline_size = 4;
          };
        }
        { plugin = "switcher";
          settings = {
            next_view = "<alt> KEY_TAB";
            prev_view = "<alt> <shift> KEY_TAB";
            speed = 350;
            view_thumbnail_scale = 1.0;
          };
        }
        { plugin = "vswitch";
          settings = let
            workspaces = builtins.genList (x: x + 1) 9;
            mkBinding = lprefix: rprefix:
              builtins.map (a:
              let
                replace = builtins.replaceStrings [ "{}" ] [ (toString a) ];
                left = replace lprefix;
                right = replace rprefix;
              in { "${left}" = "${right}"; }) workspaces;
            mergeAttrs = lib.foldl lib.recursiveUpdate { };
            workspacesAttrs = mergeAttrs (lib.flatten [
              (mkBinding "binding_{}" "<super> KEY_{}")
              (mkBinding "with_win_{}" "<super> <shift> KEY_{}")
              (mkBinding "send_win_{}" "<super> <ctrl> KEY_{}")
            ]);
          in {
            # Disable default keybinds
            binding_down = "";
            binding_up = "";
            binding_left = "";
            binding_right = "";
            binding_last = "";
            with_win_down = "";
            with_win_up = "";
            with_win_left = "";
            with_win_right = "";
            send_win_down = "";
            send_win_up = "";
            send_win_left = "";
            send_win_right = "";
          } // workspacesAttrs;
        }
        { plugin = "scale";
          settings = {
            toggle = "<super> KEY_TAB";
            toggle_all = "<super> <shift> KEY_TAB";
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
        { plugin = "expo";
          settings = let
            workspaces = builtins.genList (x: x + 1) 9;
            bindings = builtins.map (a: {
              "select_workspace_${toString a}" = "KEY_${toString a}";
            }) workspaces;
            workspacesAttrs = lib.foldl (a: b: a // b) {} bindings;
          in { toggle = "<super> <shift>"; } // workspacesAttrs;
        }
        { plugin = "grid";
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
        { plugin = "animate";
          settings = {
            close_animation = "zoom";
            open_animation = "zoom";
            zoom_duration = 250;
            enabled_for = "(role is \"TOPLEVEL\") | (role is \"DESKTOP_ENVIRONMENT\")";
            zoom_enabled_for = "(role is \"TOPLEVEL\") | (role is \"DESKTOP_ENVIRONMENT\")";
          };
        }
        { plugin = "autostart";
          settings = {
            importEnv = ''
              systemctl --user import-environment DISPLAY WAYLAND_DISPLAY \
              hash dbus-update-activation-environment @>/dev/null && dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY
            '';
            screenshare = ''
              sleep 1 && (XDG_SESSION_TYPE=wayland XDG_CURRENT_DESKTOP=sway ${pkgs.xdg-desktop-portal}/libexec/xdg-desktop-portal --replace & ${pkgs.xdg-desktop-portal-wlr}/libexec/xdg-desktop-portal-wlr)
            '';
            idle = ''
              ${pkgs.swayidle}/bin/swayidle -w \
                timeout 600 '${pkgs.fish}/bin/fish -c ${./outputs.fish} --off' \
                resume '${pkgs.fish}/bin/fish -c ${./outputs.fish} --on'
            '';
          };
        }
        { plugin = "command";
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
        { plugin = "input";
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
