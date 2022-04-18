{ config, pkgs, ... }:

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
      fzf-lua
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
      (nvim-treesitter.withPlugins builtins.attrValues)
      nvim-web-devicons
    ] ++ builtins.map (plugin: { inherit plugin; optional = true; }) [
      playground
    ];
    extraPackages = with pkgs; [
      # ccls # C/C++ LSP
      # clang-tools # C/C++ LSP and code formatter
      # cppcheck # C/C++ code linter
      fzf
      fd # Telescope finder
      luajitPackages.luacheck # Lua linter
      nixfmt # Nix code formatter
      # nodePackages.pyright # Python LSP
      # python310Packages.black # Python code formatter
      # python310Packages.flake8 # Python linter
      rnix-lsp # Nix LSP
      statix # Nix code linter
      stylua # Lua code formatter
      sumneko-lua-language-server # Lua LSP
      # texlab # LaTeX LSP
      tree-sitter # Incremental parser
      # valgrind # Memory debugging
    ];
    withRuby = false;
    withPython3 = false;
    extraConfig = "lua require('init')";
  };

  home.file.".config/nvim/lua".source = ./lua;

  programs.fish.interactiveShellInit = ''
    set EDITOR nvim
  '';
}

