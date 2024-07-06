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

      # The reason why this is not in programs.fish.shellAliases is that $argv
      # is automatically provided before the end of the function, which makes
      # sense for declaring aliases, but this leads to less workarounds. However,
      # we cannot put this in ./functions/ls.fish, because then the built-in `ls`
      # alias takes precedence for some reason.
      function ls --wraps eza
        set -l flags (path filter -v -- $argv | string match -rg '^\./(-.*)$')
        set -l entries (path normalize -- $argv | string match -rv '^\./' | path resolve; or pwd)
        command eza -TL1 --group-directories-first --icons=auto $flags $entries
      end

      # Syntax highlighting seems to be disabled under some terminal emulators.
      # Enforce default theme explicitly.
      set -l theme "fish default"
      fish_config theme choose $theme

      # The above will not export the theme colour variables to functions and
      # scripts, which is why the following is used to export the theme variables.
      fish_config theme dump $theme | while read -l line; echo "set -Ux $line"; end | source
    '';
  };
}
