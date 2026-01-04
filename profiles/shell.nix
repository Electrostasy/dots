{ config, pkgs, ... }:

let
  poimandres = pkgs.writeText "poimandres.theme" ''
    [dark]
    fish_color_autosuggestion 506477 --italic
    fish_color_cancel d0679d --reverse
    fish_color_command 89ddff
    fish_color_comment 4b4f5c
    fish_color_cwd 5fb3a1
    fish_color_cwd_root d0679d
    fish_color_end 91b4d5
    fish_color_error d0679d
    fish_color_escape 5fb3a1
    fish_color_history_current --bold
    fish_color_host e4f0fb
    fish_color_host_remote fffac2
    fish_color_keyword 91b4d5
    fish_color_normal e3f0fb
    fish_color_operator add7ff
    fish_color_option 7390aa
    fish_color_param 91b4d5
    fish_color_quote fffac2
    fish_color_redirection add7ff
    fish_color_search_match e4f0fb --background=1b1e28 --bold
    fish_color_selection e4f0fb --background=1b1e28 --bold
    fish_color_status d0679d
    fish_color_user 5de4c7
    fish_color_valid_path 5fb3a1 --underline
    fish_pager_color_completion e3f0fb
    fish_pager_color_description 42675a --italic
    fish_pager_color_prefix 5fb3a1
    fish_pager_color_progress 506477 --reverse --italic
    fish_pager_color_selected_background --background=313a48
    fish_pager_color_selected_completion e3f0fb --background=313a48
    fish_pager_color_selected_description e3f0fb --background=313a48 --italic
    fish_pager_color_selected_prefix 5fb3a1 --background=313a48
  '';

  installPoimandresTheme = "L+ %h/.config/fish/themes/poimandres.theme - - - - ${poimandres}";
in

{
  preservation.preserveAt."/persist/state".users.electro.directories = [
    # https://github.com/fish-shell/fish-shell/issues/8627
    ".local/share/fish"
  ];

  # Fish only reads extra themes from $__fish_config_dir/themes which evaluates
  # to ~/.config/fish/themes. Install theme for root and other users.
  systemd.tmpfiles.rules = [ installPoimandresTheme ];
  systemd.user.tmpfiles.rules = [ installPoimandresTheme ];

  environment = {
    systemPackages = [
      pkgs.btop
      pkgs.eza
    ];

    variables = {
      TIME_STYLE = "+%Y-%m-%d %H:%M:%S"; # affects `ls`, `eza`.
    };
  };

  users.defaultUserShell = config.programs.fish.package;

  programs.fish = {
    enable = true;
    useBabelfish = true;

    interactiveShellInit = /* fish */ ''
      set -g fish_greeting # disable greeting.

      fish_config theme choose poimandres

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
    '';
  };
}
