{ pkgs, lib, ... }:

{
  home.stateVersion = "22.11";

  home.packages = with pkgs; [
    firefox-custom
    (nerdfonts.override { fonts = [ "Iosevka" ]; })
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

  programs = {
    rofi = {
      enable = true;

      package = pkgs.rofi-wayland;
      plugins = [ ];
      terminal = "${pkgs.kitty}/bin/kitty";
      extraConfig = {
        modi = "drun,run";
        kb-primary-paste = "Control+V";
        kb-secondary-paste = "Control+v";
      };
    };

    lsd = {
      enable = true;

      settings = {
        classic = false;
        blocks = [ "permission" "user" "group" "size" "date" "name" ];
        date = "+%Y-%m-%d %H:%M:%S %z";
        dereference = true;
        sorting = {
          column = "name";
          dir-grouping = "first";
        };
      };
    };
  };
}
