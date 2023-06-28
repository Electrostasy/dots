{
  home-manager.users.pi = { config, pkgs, ... }: {
    imports = [
      ../../profiles/user/lsd
    ];

    home.stateVersion = "22.05";
  };
}
