{
  home-manager.users.gediminas = { pkgs, ... }: {
    imports = [
      ../../profiles/user/fish
      ../../profiles/user/lsd
      ../../profiles/user/neovim
      ../../profiles/user/tealdeer
    ];

    home.stateVersion = "22.11";

    home.packages = with pkgs; [
      du-dust
      fio
      libewf
      virt-manager
    ];

    programs = {
      bottom = {
        enable = true;

        settings.flags.tree = true;
      };
    };
  };
}
