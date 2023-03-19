{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;

    plugins = with pkgs.vimPlugins; [
      # Completion engine and sources.
      cmp-buffer
      cmp_luasnip
      cmp-nvim-lsp
      cmp-nvim-lua
      cmp-path
      cmp-under-comparator
      luasnip
      nvim-cmp

      # Visual improvements.
      hlargs-nvim
      indent-blankline-nvim
      lsp_lines-nvim
      nvim-colorizer-lua
      nvim-treesitter.withAllGrammars
      nvim-web-devicons

      # Functionality.
      comment-nvim
      gitsigns-nvim
      nvim-surround
      telescope-fzf-native-nvim
      telescope-nvim
      treesj
    ] ++ builtins.map (plugin: { inherit plugin; optional = true; }) [
      # Tree-sitter AST inspection.
      playground
    ];

    extraPackages = with pkgs; [
      # Lua LSP & linter.
      lua-language-server
      # selene

      # Nix doc searcher, LSP & linter.
      # manix
      nil
      # statix

      # Python LSP, formatter & linter.
      python311Packages.jedi-language-server
      # ruff

      # Rust linter, LSP & formatter.
      # clippy
      rust-analyzer
      # rustfmt

      # C/C++ LSP & formatter.
      clang-tools

      # Zig LSP.
      zls

      # Plugin dependencies.
      ripgrep
    ];

    withRuby = false;
    withPython3 = false;
    withNodeJs = false;
  };

  # Configuration is written in lua, copy it to the Nix store and symlink it
  # to ~/.config/nvim.
  home.file.".config/nvim".source = ./nvim;

  home.sessionVariables = {
    EDITOR = "nvim";
    MANPAGER = "nvim -c 'set ft=man bt=nowrite noswapfile nobk shada=\\\"NONE\\\" ro noma' +Man! -o -";
  };
}
