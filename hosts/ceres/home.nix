{ pkgs, ... }:

{
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
}
