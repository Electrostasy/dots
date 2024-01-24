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
      telescope-zf-native-nvim
      telescope-nvim
      treesj
    ];

    extraPackages = with pkgs; [
      clang-tools
      lua-language-server
      nil
      python311Packages.jedi-language-server
      ripgrep
      rust-analyzer
      wl-clipboard
      zls
    ];

    withRuby = false;
    withPython3 = false;
    withNodeJs = false;
  };

  # Configuration is written in Lua, copy it to the Nix store and symlink it
  # to ~/.config/nvim.
  home.file.".config/nvim".source = ./nvim;

  home.sessionVariables = {
    EDITOR = "nvim";
    MANPAGER = "nvim -c 'set ft=man bt=nowrite noswapfile nobk shada=\\\"NONE\\\" ro noma' +Man! -o -";
  };
}
