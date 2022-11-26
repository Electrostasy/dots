{ pkgs, ... }:

{
  imports = [ ../git-headless ];

  programs.git.config = {
    credential."https://github.com/Electrostasy/dots.git" = {
      helper = "${pkgs.git-credential-keepassxc}/bin/git-credential-keepassxc";
    };
  };
}
