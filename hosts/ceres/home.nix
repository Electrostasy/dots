{
  home-manager.users.gediminas = { pkgs, ... }: {
    imports = [
      ../../profiles/user/kitty
      ../../profiles/user/mpv
      ../../profiles/user/neovim
      ../../profiles/user/tealdeer
      ../../profiles/user/wayfire
      ../../profiles/user/zathura
    ];

    home.stateVersion = "22.11";

    home.packages = with pkgs; [
      detox
      du-dust
      fio
      libewf
      magic-wormhole-rs
      neo
      virt-manager
    ];

    wayland.windowManager.wayfire.settings.plugins = [
      { plugin = "output:DVI-I-2";
        settings.mode = "1680x1050@59882999";
      }
    ];
  };
}
