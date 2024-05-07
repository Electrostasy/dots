{
  home-manager.users.electro = { config, pkgs, lib, ... }: {
    home.stateVersion = "22.11";

    home.pointerCursor = {
      package = pkgs.simp1e-cursors;
      name = "Simp1e-Adw-Dark";
      size = 24;

      x11.enable = true;
    };
  };
}
