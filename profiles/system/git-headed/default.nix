{ pkgs, ... }:

{
  imports = [ ../git-headless ];

  programs.git.config = {
    credential."https://github.com/electrostasy/dots.git" = {
      helper = "${pkgs.git-credential-keepassxc}/bin/git-credential-keepassxc";
    };
  };
}
