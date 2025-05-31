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
      set -g fish_greeting # Disable greeting.

      function ls --wraps eza
        set -l flags (path filter -v -- $argv | string match -rg '^\./(-.*)$')
        set -l entries (path normalize -- $argv | string match -rv '^\./' | path resolve; or pwd)
        command eza -TL1 --group-directories-first --icons=auto $flags $entries
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
