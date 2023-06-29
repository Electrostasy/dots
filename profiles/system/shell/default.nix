{ pkgs, ... }:

{
  environment = {
    sessionVariables.TIME_STYLE = "long-iso";
    systemPackages = with pkgs; [
      bottom
      erdtree
      exa
      fd
      file
      ripgrep
      vimv-rs
    ];
  };

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

  # TODO: Why are ll, l shell aliases being added?
  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      function ls
        argparse 'l/long' 'a/all' 'd/depth=' -- $argv
        set -l exa_args (string match -v -- '-*' $argv)
        if test (count $exa_args) -eq 0
          set exa_args .
        end

        for i in (seq (count $exa_args))
          set exa_args[$i] (readlink -m $exa_args[$i])
        end

        set -l exa_flags --tree --group-directories-first --icons
        set exa_flags $exa_flags --level=(test -n "$_flag_depth" && echo $_flag_depth || echo 1)
        if set -q _flag_long
          set exa_flags $exa_flags --long --group
        end
        if set -q _flag_all
          set exa_flags $exa_flags --all
        end

        command exa $exa_flags $exa_args
      end

      set -l fish_greeting # Disable greeting.

      # By default, syntax highlighting seems to be disabled. Enforce default
      # theme. We could use `fish_config theme choose`, but that will not
      # export the theme colour variables to other functions and scripts.
      fish_config theme dump "fish default" | while read -l line; echo "set -Ux $line"; end | source

      # Prompt configuration.
      function fish_right_prompt -d "Print the right-side prompt"
        set_color $fish_color_autosuggestion; date '+%H:%M:%S'
        if test $CMD_DURATION && test $CMD_DURATION -ne 0
          echo " "
          set_color $fish_color_quote; echo "$(math "$CMD_DURATION/1000")s"
        end
      end

      # Custom command-not-found handler using nix-index and syntax highlights.
      function __fish_command_not_found_handler --on-event fish_command_not_found
        set -l query $argv[1]
        set -l attrs (command nix-locate --minimal --no-group --type x --type s --top-level --whole-name --at-root "/bin/$query")
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
