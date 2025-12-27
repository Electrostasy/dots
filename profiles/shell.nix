{ config, pkgs, lib, ... }:

{
  preservation.preserveAt."/persist/state".users.electro.directories = [
    # https://github.com/fish-shell/fish-shell/issues/8627
    ".local/share/fish"
  ];

  environment = {
    systemPackages = [
      pkgs.btop
      pkgs.command-not-found
      pkgs.eza
    ];

    variables = {
      TIME_STYLE = "+%Y-%m-%d %H:%M:%S"; # affects `ls`, `eza`.
    };
  };

  users.defaultUserShell = config.programs.fish.package;

  # TODO: When https://github.com/NixOS/nixpkgs/pull/415070 is merged, remove
  # these and set our command-not-found as programs.command-not-found.package.
  programs.bash.interactiveShellInit = ''
    command_not_found_handle() {
      "${lib.getExe pkgs.command-not-found}" "$@"
    }
  '';

  programs.zsh.interactiveShellInit = ''
    command_not_found_handler() {
      "${lib.getExe pkgs.command-not-found}" "$@"
    }
  '';

  programs.fish = {
    enable = true;

    interactiveShellInit = /* fish */ ''
      set -g fish_greeting # disable greeting.

      function fish_right_prompt -d "Print the right-side prompt"
        # Print the command duration.
        if test $CMD_DURATION && test $CMD_DURATION -ne 0
          set_color $fish_color_quote; echo "$(math "$CMD_DURATION/1000")s"
        end

        # If we are in a Nix shell, print a Nix snowflake.
        # Based on: https://github.com/NixOS/nix/issues/3862#issuecomment-707320241
        if test $SHLVL -gt 1 && string match -q -- '/nix/store/*' $PATH[1]
          set_color 7AB1DB; echo '  '
        end
      end

      function ls --wraps eza
        set -l flags (path filter -v -- $argv | string match -rg '^\./(-.*)$')
        set -l entries (path normalize -- $argv | string match -rv '^\./' | path resolve; or pwd)
        command eza -gTL1 --binary --group-directories-first --icons=auto $flags $entries
      end

      function ? --description 'Print a list of all executables provided by this Nix shell'
        if not test $SHLVL -gt 1 && string match -q -- '/nix/store/*' $PATH[1]
          echo 'Not in Nix shell!'
          return 1
        end

        echo 'The following executables are provided by this ephemeral shell:'
        for entry in $PATH
          # Some programs installed with Nix will append themselves to PATH, so
          # we only check the entries prepended to PATH by Nix.
          if not string match -q '/nix/store/*' -- $entry
            break
          end

          # Assuming the bin, libexec, etc. directories are added to PATH, we
          # can get the package name from the parent directory.
          echo "$(path dirname $entry | string sub --start 45):"
          for executable in (path basename $entry/*)
            echo "  $executable"
          end
        end
      end

      # TODO: Configure theme independent of the terminal emulator theme.
      set -U fish_color_cancel red --reverse
      set -U fish_color_command brcyan
      set -U fish_color_comment white
      set -U fish_color_cwd green
      set -U fish_color_end blue
      set -U fish_color_error red
      set -U fish_color_operator brblue
      set -U fish_color_param cyan
      set -U fish_color_quote bryellow
      set -U fish_color_redirection blue
      set -U fish_color_valid_path green --underline
    '';
  };
}
