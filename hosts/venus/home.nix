{
  home-manager.users.electro = { pkgs, lib, ... }: {
    imports = [
      ../../profiles/user/mpv
      ../../profiles/user/neovim
      ../../profiles/user/tealdeer
      ../../profiles/user/zathura
    ];

    home.stateVersion = "22.11";

    home.pointerCursor = {
      package = pkgs.simp1e-cursors;
      name = "Simp1e-Adw-Dark";
      size = 24;

      x11.enable = true;
    };

    home.packages = with pkgs; [
      freerdp # wlfreerdp
      imv
      keepassxc
      liberation_ttf # Replacement fonts for TNR, Arial and Courier New
      libreoffice-fresh
      magic-wormhole-rs
      mepo
      nurl
      qr
      xournalpp
    ];
  };
}
