{ pkgs, lib, ... }:

{
  environment.systemPackages = [
    pkgs.gnomeExtensions.brightness-control-using-ddcutil
    pkgs.ddcutil
  ];

  programs.dconf.profiles.user.databases = [{
    settings = with lib.gvariant; {
      "org/gnome/shell/extensions/display-brightness-ddcutil" = {
        button-location = mkInt32 1;
        hide-system-indicator = true;
        show-all-slider = true;
        show-sliders-in-submenu = true;
        show-display-name = false;

        # The extension will not work nor load the above settings correctly
        # unless these keys are present.
        ddcutil-binary-path = lib.getExe pkgs.ddcutil;
        ddcutil-queue-ms = mkDouble 130.0;
        ddcutil-sleep-multiplier = mkDouble 40.0;
      };
    };
  }];

  hardware.i2c.enable = true;

  services.udev.extraRules = /* udev */ ''
    # uaccess tags do not work with the GNOME extension:
    # https://www.ddcutil.com/i2c_permissions/
    # https://www.ddcutil.com/i2c_permissions_using_group_i2c/
    KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
  '';

  users = {
    users.electro.extraGroups = [ "i2c" ];
    groups.i2c = { };
  };
}
