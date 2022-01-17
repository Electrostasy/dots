{ config, pkgs, ... }:

{
  gtk = {
    enable = true;
    font = {
      name = "Inter Medium 10.5";
      package = pkgs.inter;
    };
    theme = {
      name = "Materia-dark-compact";
      package = pkgs.materia-theme;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };
  };
}
