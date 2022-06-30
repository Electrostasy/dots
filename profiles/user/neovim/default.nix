{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      cmp-buffer
      cmp_luasnip
      cmp-nvim-lsp
      cmp-nvim-lua
      cmp-path
      cmp-under-comparator
      gitsigns-nvim
      heirline-nvim
      hlargs-nvim
      indent-blankline-nvim
      jq-vim
      kanagawa-nvim
      lightspeed-nvim
      lspkind-nvim
      luasnip
      null-ls-nvim
      nvim-cmp
      nvim-colorizer-lua
      nvim-lspconfig
      (nvim-treesitter.withPlugins (_: pkgs.tree-sitter.allGrammars))
      nvim-web-devicons
      telescope-fzf-native-nvim
      telescope-nvim
    ] ++ builtins.map (plugin: { inherit plugin; optional = true; }) [
      playground
    ];
    extraPackages = with pkgs; [
      fd
      fzf
      luajitPackages.luacheck
      nixfmt
      rnix-lsp
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
    set -x MANPAGER 'nvim -c "set ft=man" +Man! -o -'
  '';
}
