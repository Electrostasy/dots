{ pkgs, lib, ... }:

{
  home.stateVersion = "22.11";

  home.packages = with pkgs; [
    firefox-custom
    iosevka-nerdfonts
    rnote
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
        command_orientation = builtins.toString ./rotate_screen.sh;
      };
    }
    { plugin = "scale";
      settings.toggle = "<super> KEY_TAB | KEY_CYCLEWINDOWS";
    }
  ];
}
