{ config, home-manager, pkgs, ... }:

{
  programs.broot = {
    enable = true;
    package = pkgs.broot;
    enableZshIntegration = true; # `br {args}` 
    verbs = [
      {
        invocation = "p";
        internal = ":parent";
      }
      {
        invocation = "home";
        key = "ctrl-h";
        internal = ":focus ~/";
      }
      {
        invocation = "root";
        key = "ctrl-/";
        internal = ":focus /";
      }
      {
        invocation = "edit";
        shortcut = "e";
        external = "$EDITOR {file}";
        from_shell = true;
      }
      {
        invocation = "watch";
        shortcut = "w";
        external = "mpv {file}";
        leave_broot = false;
      }
    ];
  };
}
