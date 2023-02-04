{
  home-manager.users.electro = { pkgs, lib, ... }: {
    imports = [
      ../../profiles/user/fish
      ../../profiles/user/kitty
      ../../profiles/user/lsd
      ../../profiles/user/mpv
      ../../profiles/user/neovim
      ../../profiles/user/tealdeer
      ../../profiles/user/wayfire
      ../../profiles/user/zathura
    ];

    home.stateVersion = "22.11";

    home.packages = with pkgs; [
      element-desktop
      firefox-custom
      imv
      keepassxc
      liberation_ttf # Replacement fonts for TNR, Arial and Courier New
      libreoffice
      mepo
      xournalpp
    ];

    wayland.windowManager.wayfire.settings.plugins = lib.mkOrder 0 [
      # Digitizer to display mappings for rotation
      # https://github.com/WayfireWM/wayfire/issues/335
      # https://github.com/WayfireWM/wayfire/wiki/Configuration#input-device-specific-options
      { plugin = "input-device:Wacom ISDv4 E6 Pen"; settings.output = "LVDS-1"; }
      { plugin = "input-device:Wacom ISDv4 E6 Finger"; settings.output = "LVDS-1"; }

      { plugin = "command";
        settings = {
          binding_orientation = "KEY_ROTATE_DISPLAY";
          command_orientation = lib.getExe (pkgs.writeShellApplication {
            name = "rotate-screen";
            runtimeInputs = with pkgs; [
              wlr-randr
              gawk
            ];
            text = "wlr-randr | awk -f ${./rotate_screen.awk}";
          });
          binding_showvk = "swipe up 2";
          command_showvk = "${pkgs.util-linux}/bin/kill -s USR2 wvkbd-mobintl";
          binding_hidevk = "swipe down 2";
          command_hidevk = "${pkgs.util-linux}/bin/kill -s USR1 wvkbd-mobintl";
        };
      }
      { plugin = "autostart";
        settings.virtual_keyboard = ''
          ${pkgs.wvkbd}/bin/wvkbd-mobintl \
            --bg 16161d --fg 223249 --fg-sp 223249 \
            --press 2d4f67 --press-sp 2d4f67 \
            -l simple --hidden
        '';
      }
      { plugin = "scale";
        settings.toggle = "<super> KEY_TAB | KEY_CYCLEWINDOWS";
      }
    ];
  };
}
