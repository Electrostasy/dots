{ config, pkgs, ... }:

{
  preservation.preserveAt = {
    "/persist/cache".users.electro.directories = [
      # tealdeer removes the entire tldr-pages subdirectory, so we cannot
      # persist it, but instead we persist the parent directory.
      ".cache/tealdeer"
    ];

    "/persist/state".users.electro.directories = [
      # https://github.com/fish-shell/fish-shell/issues/8627
      ".local/share/fish"
    ];
  };

  environment = {
    systemPackages = with pkgs; [
      aria2
      btop
      eza
      fd
      file
      jq
      magic-wormhole-rs
      ouch
      qrtool
      ripgrep
      rsync
      tealdeer
      vimv-rs

      (pkgs.runCommandLocal "install-fish-functions" { } ''
        install -Dm0444 -t $out/share/fish/vendor_functions.d ${builtins.path { path = ./functions; name = "source"; }}/{hyperlink,phobos-up,nixpkgs-pr,fish_right_prompt}.fish
        install -Dm0444 -t $out/share/fish/vendor_functions.d ${pkgs.replaceVarsWith {
          src = "${builtins.path { path = ./functions; name = "source"; }}/fish_command_not_found.fish";

          replacements = {
            inherit (pkgs) sqlite path;
          };

          dir = "bin";
        }}/bin/fish_command_not_found.fish
      '')
    ];

    shellAliases = {
      a2c = "aria2c";
      wh = "wormhole-rs";
    };

    sessionVariables = {
      TIME_STYLE = "+%Y-%m-%d %H:%M:%S"; # for `ls`, `eza`.
    };
  };

  users.defaultUserShell = config.programs.fish.package;

  programs.fish = {
    enable = true;

    interactiveShellInit = /* fish */ ''
      set -g fish_greeting # disable greeting.

      function ls --wraps eza
        set -l flags (path filter -v -- $argv | string match -rg '^\./(-.*)$')
        set -l entries (path normalize -- $argv | string match -rv '^\./' | path resolve; or pwd)
        command eza -TL1 --binary --group-directories-first --icons=auto $flags $entries
      end

      function ? --description 'Print a list of all executables provided by this Nix shell'
        if test $SHLVL -gt 1 && string match -q -- '/nix/store/*' $PATH[1]
          echo 'The following executables are provided by this ephemeral shell:'
          set -f input
          set -f id 1
          for store_path in (string match -- '/nix/store/*' $PATH | path filter | sort -t - -k 2)
            set -f name (nix derivation show $store_path | jq -r '.[].env | .version as $version | .name | sub("-\($version).*"; "")')
            set -f parent $id
            set -a input "$id $parent $name"
            set id (math "$id + 1")
            for executable in (fd . $store_path -t x -L --format '{/}' | ${pkgs.coreutils-full}/bin/sort -u)
              set -a input "$id $parent $executable"
              set id (math "$id + 1")
            end
          end

          printf '%s\n' $input | ${pkgs.util-linux}/bin/column --tree-id 1 --tree-parent 2 --tree 3 --table-hide 1,2
        else
          echo 'Not in Nix shell!'
        end
      end

      set -Ux fish_color_cancel red --reverse
      set -Ux fish_color_command brcyan
      set -Ux fish_color_comment white
      set -Ux fish_color_cwd green
      set -Ux fish_color_end blue
      set -Ux fish_color_error red
      set -Ux fish_color_operator brblue
      set -Ux fish_color_param cyan
      set -Ux fish_color_quote bryellow
      set -Ux fish_color_redirection blue
      set -Ux fish_color_valid_path green --underline
    '';
  };
}
