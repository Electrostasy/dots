{
  home-manager.users.electro = { pkgs, ... }: {
    imports = [
      ../../profiles/user/kitty
      ../../profiles/user/mpv
      ../../profiles/user/neovim
      ../../profiles/user/wayfire
    ];

    home.stateVersion = "22.11";

    home.packages = with pkgs; [
      libewf
      virt-manager
    ];

    wayland.windowManager.wayfire.settings.plugins = [
      { plugin = "output:DVI-I-2";
        settings.mode = "1680x1050@59882999";
      }
    ];
  };
}
