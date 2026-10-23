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
      # Without bash present in PATH, nixos-install does not seem to work (or
      # any scripts depending on BASH in PATH for that matter).
      pkgs.bashInteractive
      pkgs.coreutils-full
      pkgs.util-linux
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

      # https://github.com/NixOS/nix/issues/3862#issuecomment-707320241
      function in_nix_shell
        test $SHLVL -gt 1; and string match -q -- '/nix/store/*' $PATH[1]
      end

      function fish_right_prompt --description 'Print the right-side prompt'
        if in_nix_shell
          set_color 7AB1DB
          printf '\uF313 '
          set_color normal
        end
      end

      function ls --wraps eza
        command eza --group --tree --level=1 --binary --group-directories-first --icons=auto --git $argv
      end

      function 0 --wraps run0
        echo -ne '\e]11;rgb:26/21/2d\e\\' # set the default background colour.

        command run0 --background= --shell-prompt-prefix='🛡️ ' $argv

        if test $EUID != 0
          echo -ne '\e]111;\e\\' # reset the default background colour.
        end
      end

      function ? --description 'Resolve executables to Nix store paths'
        if test (count $argv) -gt 0
          set -l paths (command -s $argv | path resolve)

          set -l paths_nix (string match -a '/nix/store/*' -- $paths)
          if test (count $paths_nix) -gt 0
            echo 'The following executables resolved to Nix store paths:'
            printf '  %s\n' $paths_nix
          end

          set -l paths_other (string match -av '/nix/store/*' -- $paths)
          if test (count $paths_other) -gt 0
            echo 'The following executables resolved to other paths:'
            printf '  %s\n' $paths_other
          end

          return
        end

        # If no arguments are provided, interrogate PATH for Nix store paths
        # under the condition that we are in a Nix shell.
        if not in_nix_shell
          return 1
        end

        set -l paths

        # Nix shell installed programs are prepended to PATH, some (rarely)
        # NixOS installed programs are appended to PATH. Collect all the paths
        # up to the first non-Nix store path.
        for path in $PATH
          if not string match -q '/nix/store/*' -- $path
            break
          end

          set -a paths $path
        end

        if test (count $paths) -gt 0
          echo 'The following executables are provided by this ephemeral shell:'
          printf '  %s\n' (path filter --type file --perm exec $paths/*)
        else
          echo 'No executables are provided by this ephemeral shell.'
        end
      end
    '';
  };
}
