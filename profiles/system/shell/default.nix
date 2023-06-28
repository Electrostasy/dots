{ config, pkgs, ... }:

{
  programs.nix-index = {
    enable = true;

    enableZshIntegration = false;
    enableBashIntegration = false;
    # We use our own command-not-found handler in
    # programs.fish.interactiveShellInit.
    enableFishIntegration = false;
  };

  # By default, the user shell is set to pkgs.shadow, this overrides it.
  users.defaultUserShell = pkgs.fish;

  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      set -l fish_greeting # Disable greeting.

      # By default, syntax highlighting seems to be disabled. Enforce default
      # theme. We could use `fish_config theme choose`, but that will not
      # export the theme colour variables to other functions and scripts.
      fish_config theme dump "fish default" | while read -l line; echo "set -Ux $line"; end | source

      # Prompt configuration.
      function fish_right_prompt -d "Print the right-side prompt"
        set_color $fish_color_autosuggestion; date '+%H:%M:%S'
      end

      # Custom command-not-found handler using nix-index and syntax highlights.
      function __fish_command_not_found_handler --on-event fish_command_not_found
        set -l query $argv[1]
        set -l attrs (${config.programs.nix-index.package}/bin/nix-locate --minimal --no-group --type x --type s --top-level --whole-name --at-root "/bin/$query")
        set attrs (string replace '.out' '''''' $attrs | string collect | sort)

        echo -n "The program '"
        set_color $fish_color_error; echo -n "$query"

        if string trim $attrs | string length --quiet
          set_color $fish_color_normal; echo -n "' is not installed."
        else
          set_color $fish_color_normal; echo "' could not be located."
          return 127
        end

        if [ (count $attrs) -gt 1 ]
          echo " It is provided by several packages."
        else
          echo ""
        end
        echo -n "Spawn a shell containing '"
        set_color $fish_color_error; echo -n "$query"
        set_color $fish_color_normal; echo "':"

        for attr in $attrs
          echo -n "  $(echo "nix shell nixpkgs#$attr" | fish_indent --ansi --no-indent)"
        end
        echo -e "\nOr run it once with:"
        for attr in $attrs
          echo -n "  $(echo "nix run nixpkgs#$attr" | fish_indent --ansi --no-indent)"
        end

        set_color $fish_color_normal
      end
    '';
  };
}
