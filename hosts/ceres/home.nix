{
  home-manager.users.electro = { pkgs, ... }: {
    imports = [
      ../../profiles/user/kitty
      ../../profiles/user/wayfire
    ];

    home.stateVersion = "22.11";

    wayland.windowManager.wayfire.settings.plugins = [
      { plugin = "output:DVI-I-2";
        settings.mode = "1680x1050@59882999";
      }
    ];
  };
}
