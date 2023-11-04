{
  home-manager.users.electro = { config, pkgs, lib, ... }: {
    imports = [
      ../../profiles/user/mpv
      ../../profiles/user/neovim
      ../../profiles/user/tealdeer
      ../../profiles/user/zathura
    ];

    home.stateVersion = "22.11";

    xdg.userDirs = {
      enable = true;

      desktop = null; # unused
      documents = "${config.home.homeDirectory}/documents";
      download = "${config.home.homeDirectory}/downloads";
      music = "${config.home.homeDirectory}/music";
      pictures = "${config.home.homeDirectory}/pictures";
      publicShare = null; # unused
      templates = null; # unused
      videos = "${config.home.homeDirectory}/videos";
    };

    home.pointerCursor = {
      package = pkgs.simp1e-cursors;
      name = "Simp1e-Adw-Dark";
      size = 24;

      x11.enable = true;
    };

    home.packages = with pkgs; [
      freerdp # xfreerdp
      imv
      keepassxc
      liberation_ttf # Replacement fonts for TNR, Arial and Courier New
      libreoffice-fresh
      mepo
      nurl
      rnote
      xournalpp
    ];
  };
}
