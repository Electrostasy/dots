{
  home-manager.users.gediminas = { config, pkgs, ... }: {
    imports = [
      ../../profiles/user/fish
      ../../profiles/user/kitty
      ../../profiles/user/lsd
      ../../profiles/user/neovim
      ../../profiles/user/tealdeer
      ../../profiles/user/wayfire
      ../../profiles/user/zathura
    ];

    home.stateVersion = "22.11";

    xdg.enable = true;

    home.packages = with pkgs; [
      firefox-custom
      liberation_ttf # Replacement fonts for TNR, Arial and Courier New
      # Wait for https://github.com/NixOS/nixpkgs/pull/212583
      # to hit nixos-unstable, broken build.
      # libreoffice
      source-han-sans # Japanese OpenType/CFF fonts
      xplr
    ];

    fonts.fontconfig.enable = true;
  };
}

