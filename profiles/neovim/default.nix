{ config, pkgs, lib, ... }:

{
  preservation.preserveAt."/persist/state".users.electro.directories = [
    ".local/state/nvim"
    ".local/share/nvim"
  ];

  # TODO: Refactor to `systemd.user.tmpfiles.settings` when
  # https://github.com/NixOS/nixpkgs/pull/317383 is merged.
  systemd.user.tmpfiles.rules = [
    # Link the Lua config for Neovim.
    "L+ %h/.config/nvim - - - - ${./nvim}"

    # Override the Neovim wrapper's .desktop file with our own less weird name.
    "L+ %h/.local/share/applications/nvim.desktop - - - - ${
      let
        drv = pkgs.runCommand "modify-nvim-desktop" {} ''
          mkdir -p $out
          substitute ${config.programs.neovim.finalPackage}/share/applications/nvim.desktop $out/nvim.desktop \
            --replace-warn 'Name=Neovim wrapper' 'Name=Neovim'
        '';
      in "${drv}/nvim.desktop"
    }"
  ];

  xdg.mime.defaultApplications."text/plain" = "nvim.desktop";

  environment.variables = {
    EDITOR = "nvim";
    MANPAGER = "nvim -c 'set ft=man bt=nowrite noswapfile nobk shada=\\\"NONE\\\" ro noma' +Man! -o -";
  };

  programs.neovim = {
    enable = true;

    plugins = with pkgs.vimPlugins; [
      blink-cmp
      gitsigns-nvim
      hlargs-nvim
      indent-blankline-nvim
      nvim-highlight-colors
      nvim-web-devicons
      telescope-nvim
      telescope-zf-native-nvim
      treesj

      # Exclude parsers already bundled with Neovim:
      # https://neovim.io/doc/user/treesitter.html#treesitter-parsers
      (nvim-treesitter.withPlugins (ps: lib.pipe ps [
        (lib.filterAttrs (name: lib.isDerivation))

        (lib.filterAttrs (_: value: with ps; !lib.elem value [
          tree-sitter-c
          tree-sitter-lua
          tree-sitter-markdown
          tree-sitter-query
          tree-sitter-vim
          tree-sitter-vimdoc
        ]))

        lib.attrValues
      ]))
    ];

    extraPackages = with pkgs; [
      basedpyright
      clang-tools
      lua-language-server
      nixd
      ripgrep
      rust-analyzer
      zls
    ];
  };
}
