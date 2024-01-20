{
  home-manager.users.electro = { config, pkgs, lib, ... }: {
    imports = [
      ../../profiles/user/mpv
      ../../profiles/user/neovim
      ../../profiles/user/tealdeer
    ];

    home.stateVersion = "22.11";

    programs.mpv = {
      package = pkgs.celluloid;
      scripts = lib.mkForce [ ];
      config = {
        # Border is required for Celluloid's CSD to render.
        border = "yes";
        autofit-smaller = "1920x1080";
        cursor-autohide = "always";
      };
    };

    fonts.fontconfig.enable = true;

    home.packages = with pkgs; [
      f3d
      freecad
      prusa-slicer

      freerdp # xfreerdp
      gimp
      keepassxc
      libreoffice-fresh
      neo
      nurl
      pastel
      pt-p300bt-labelmaker
      qpwgraph
      spek
      xdg-utils
      youtube-dl

      ipafont
      liberation_ttf
    ];
  };
}

