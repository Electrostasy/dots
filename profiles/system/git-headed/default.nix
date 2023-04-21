{ pkgs, ... }:

{
  imports = [ ../git-headless ];

  programs.git.config = {
    credential.helper = "${pkgs.git-credential-keepassxc}/bin/git-credential-keepassxc --git-groups";
  };
}
