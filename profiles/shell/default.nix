{ config, pkgs, lib, ... }:

{
  environment = {
    systemPackages = with pkgs; [
      aria2
      bottom
      eza
      fd
      file
      jq
      magic-wormhole-rs
      ouch
      ripgrep
      rsync
      tealdeer
      vimv-rs

      # TODO: fish seems to be unable to load functions placed in /etc/fish/functions
      # without adding it to fish_function_path. We can add them to ~/.config/fish/functions
      # though.
      (pkgs.runCommandLocal "install-fish-functions" {} ''
        install -Dm0444 -t $out/share/fish/vendor_functions.d ${./functions}/*
      '')
    ];

    shellAliases = {
      a2c = "aria2c";
      wh = "wormhole-rs";
      ts = lib.mkIf config.services.tailscale.enable "tailscale";
    };

    persistence.state.users.electro.directories = [
      ".cache/nix-index"

      # tealdeer removes the entire tldr-pages subdirectory, so we cannot
      # persist it, but instead we persist the parent directory.
      ".cache/tealdeer"

      # https://github.com/fish-shell/fish-shell/issues/8627
      ".local/share/fish"
    ];
  };

  programs.nix-index = {
    enable = true;

    enableZshIntegration = false;
    enableBashIntegration = false;
    enableFishIntegration = false; # use our own command-not-found handler.
  };

  users.defaultUserShell = pkgs.fish;

  programs.fish = {
    enable = true;

    interactiveShellInit = /* fish */ ''
      set -g fish_greeting # Disable greeting.

      function ls --wraps eza
        set -l flags (path filter -v -- $argv | string match -rg '^\./(-.*)$')
        set -l entries (path normalize -- $argv | string match -rv '^\./' | path resolve; or pwd)
        command eza -TL1 --group-directories-first --icons=auto $flags $entries
      end

      set -e fish_color_cancel; set -Ux fish_color_cancel red --reverse
      set -e fish_color_command; set -Ux fish_color_command brcyan
      set -e fish_color_comment; set -Ux fish_color_comment white
      set -e fish_color_cwd; set -Ux fish_color_cwd green
      set -e fish_color_end; set -Ux fish_color_end blue
      set -e fish_color_error; set -Ux fish_color_error red
      set -e fish_color_operator; set -Ux fish_color_operator brblue
      set -e fish_color_param; set -Ux fish_color_param cyan
      set -e fish_color_quote; set -Ux fish_color_quote bryellow
      set -e fish_color_redirection; set -Ux fish_color_redirection blue
      set -e fish_color_valid_path; set -Ux fish_color_valid_path green --underline
    '';
  };
}
