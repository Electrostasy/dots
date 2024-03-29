{ osConfig, config, pkgs, lib, ... }:

{
  assertions = [
    { assertion = osConfig.hardware.opengl.enable;
      message = "hardware.opengl.enable must be set to true in NixOS config.";
    }
  ];

  imports = [
    ./dpms.nix
    ./session.nix
  ];

  home.pointerCursor = {
    package = pkgs.simp1e-cursors;
    name = "Simp1e-Adw-Dark";
    size = 24;

    x11.enable = true;
  };

  programs.fuzzel = {
    enable = true;

    settings = {
      main = {
        font = "Recursive";
        fuzzy = "yes";
        horizontal-pad = 0;
        prompt = "\'\'"; # Empty prompt
        vertical-pad = 0;
        width = 80;
      };

      colors = {
        background = "223249ff";
        border = "2d4f67ff";
        match = "ff9e3bff";
        selection = "2d4f67ff";
        selection-match = "ff9e3bff";
        selection-text = "dcd7baff";
        text = "dcd7baff";
      };

      border = {
        radius = 0;
        width = 4;
      };
    };
  };

  home.packages = with pkgs; [
    wf-recorder
    wl-clipboard
    xdg-utils
  ];

  wayland.windowManager.wayfire = {
    enable = true;

    settings = {
      close_top_view = "<super> <shift> KEY_W";
      preferred_decoration_mode = "server";
      xwayland = true;
      vheight = 3;
      vwidth = 3;

      plugins = [
        { plugin = "move"; settings.activate = "<super> BTN_LEFT"; }
        { plugin = "place"; settings.mode = "cascade"; }
        { plugin = "resize"; settings.activate = "<super> BTN_RIGHT"; }
        { plugin = "wm-actions"; settings.toggle_fullscreen = "<super> KEY_F11"; }
        { plugin = "window-rules";
          settings = {
            ff_webrtc = "on created if title is \"Firefox — Sharing Indicator\" then minimize";
          };
        }

        { package = pkgs.wayfirePlugins.shadows;
          plugin = "winshadows";
          settings = {
            include_undecorated_views = true;
            shadow_color = "\\#00000033";
            shadow_radius = 20;
            glow_color = "\\#97AFCD26";
            glow_radius = 40;
          };
        }
        { plugin = "decoration";
          settings = {
            active_color = "\\#2D4F67FF";
            inactive_color = "\\#223249FF";
            border_size = 4;
            title_height = 0;
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
            animation_transition_time = 150;
            middle_click_close = true;
            spacing = 32;
            inactive_alpha = 0.8;
            title_overlay = "mouse";
            title_font_size = 12;
            title_position = "bottom";
            bg_color = [ 0.086 0.086 0.114 1.0 ];
            text_color = [ 0.863 0.843 0.729 1.0 ];
          };
        }
        { plugin = "expo";
          settings = let
            workspaces = builtins.genList (x: x + 1) 9;
            bindings = builtins.map (a: {
              "select_workspace_${toString a}" = "KEY_${toString a}";
            }) workspaces;
            workspacesAttrs = lib.foldl (a: b: a // b) {} bindings;
          in {
            toggle = "<super> <shift>";
            background = [ 0.086 0.086 0.114 1.0 ];
          } // workspacesAttrs;
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
            enabled_for = "(role is \"TOPLEVEL\") | (role is \"DESKTOP_ENVIRONMENT\")";
            zoom_enabled_for = "(role is \"TOPLEVEL\") | (role is \"DESKTOP_ENVIRONMENT\")";
            close_animation = "zoom";
            open_animation = "zoom";
            zoom_duration = 250;
          };
        }
        { plugin = "command";
          settings = {
            binding_terminal = "<super> KEY_ENTER";
            command_terminal = "${config.programs.kitty.package}/bin/kitty";

            # Program/command launcher.
            binding_launcher = "<super> KEY_SPACE";
            command_launcher = "${config.programs.fuzzel.package}/bin/fuzzel";

            # This monstrosity of a screenshot command trims the region selected
            # by slurp so that the region borders are not captured by grim.
            binding_screenshot_interactive = "<super> <shift> KEY_S";
            command_screenshot_interactive = lib.getExe (pkgs.writeShellApplication {
              name = "screenshot";
              runtimeInputs = with pkgs; [
                slurp
                gawk
                grim
                wl-clipboard
              ];
              text = ''
                slurp -d -b \#16161daa -c \#dcd7baff -s \#00000000 -w 4 \
                | awk -F'[, x]' -v B=4 '{printf("%d,%d %dx%d",$1+B/2,$2+B/2,$3-B,$4-B)}' \
                | grim -g - - \
                | wl-copy
              '';
            });
          };
        }
        { plugin = "input";
          settings = {
            mouse_accel_profile = "flat";

            # Enable switching between keyboard layouts/languages.
            xkb_layout = "us,lt";
            xkb_model = "pc105";
            xkb_options = "grp:alt_shift_toggle";
          };
        }
      ];
    };
  };
}
