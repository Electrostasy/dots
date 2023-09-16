{ pkgs, ... }:

{
  environment = {
    sessionVariables.TIME_STYLE = "long-iso";

    systemPackages = with pkgs; [
      bottom
      erdtree
      eza
      fd
      ouch
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

  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      # TODO: find where these aliases are being set:
      # l, ll, la
      function ls
        argparse 'l/long' 'a/all' 'd/depth=' -- $argv

        # Filter directories/files from flags.
        set -l eza_args (string match -v -- '-*' $argv)

        # If there are no targets to ls, assume current working directory.
        if test (count $eza_args) -eq 0
          set eza_args .
        end

        # Convert targets to absolute paths.
        for i in (seq (count $eza_args))
          set eza_args[$i] (readlink -m $eza_args[$i])
        end

        set -l eza_flags --tree --group-directories-first --icons
        set eza_flags $eza_flags --level=(test -n "$_flag_depth" && echo $_flag_depth || echo 1)
        if set -q _flag_long
          set eza_flags $eza_flags --long --group
        end
        if set -q _flag_all
          set eza_flags $eza_flags --all
        end

        command eza $eza_flags $eza_args
      end

      set -g fish_greeting # Disable greeting.

      # By default, syntax highlighting seems to be disabled under some terminal
      # emulators. Enforce default theme explicitly.
      set -l theme "fish default"
      fish_config theme choose $theme

      # The above will not export the theme colour variables to functions and
      # scripts, which is why the following is used to export the theme variables.
      fish_config theme dump $theme | while read -l line; echo "set -Ux $line"; end | source

      function fish_right_prompt -d "Print the right-side prompt"
        set_color $fish_color_autosuggestion; date '+%H:%M:%S'
        if test $CMD_DURATION && test $CMD_DURATION -ne 0
          set_color $fish_color_quote; echo " $(math "$CMD_DURATION/1000")s"
        end
      end

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
