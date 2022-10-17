{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;

    plugins = with pkgs.vimPlugins; [
      # Completion plugins
      cmp-buffer
      cmp_luasnip
      cmp-nvim-lsp
      cmp-nvim-lua
      cmp-path
      cmp-under-comparator
      nvim-cmp

      # Eyecandy, syntax highlighting
      heirline-nvim
      hlargs-nvim
      indent-blankline-nvim
      jq-vim
      kanagawa-nvim
      lspkind-nvim
      lsp_lines-nvim
      nvim-colorizer-lua
      (nvim-treesitter.withPlugins (_: pkgs.tree-sitter.allGrammars))
      nvim-web-devicons

      # Additional functionality
      comment-nvim
      gitsigns-nvim
      luasnip
      nvim-surround
      telescope-fzf-native-nvim
      telescope-nvim

      # LSP
      null-ls-nvim
      nvim-lspconfig
    ] ++ builtins.map (plugin: { inherit plugin; optional = true; }) [
      playground
    ];

    extraPackages = with pkgs; [
      luajitPackages.luacheck
      nil
      rust-analyzer
      statix
      stylua
      sumneko-lua-language-server
      tree-sitter
    ];

    withRuby = false;
    withPython3 = false;
    extraConfig = "lua require('init')";
  };

  home.file.".config/nvim/lua".source = ./lua;

  programs.fish.interactiveShellInit = ''
    set -x EDITOR nvim
    set -x MANPAGER 'nvim -c "set ft=man nos nobk shada='NONE' ro" +Man! -o -'
  '';
}
