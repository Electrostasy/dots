{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      (nvim-treesitter.withPlugins builtins.attrValues) # tree-sitter code AST
      cmp-buffer # nvim-cmp completion buffer source
      cmp-cmdline # nvim-cmp commands completion source
      cmp-nvim-lsp # nvim-cmp completion LSP source
      cmp-nvim-lua # nvim-cmp completion Neovim Lua API source
      cmp-path # nvim-cmp completion Path source
      cmp-under-comparator # nvim-cmp completion sorter
      cmp_luasnip # nvim-cmp completion Luasnip snippets source
      editorconfig-nvim # `.editorconfig` code style support
      filetype-nvim # filetype.vim replacement
      heirline-nvim # Statusline
      indent-blankline-nvim # Indentation highlighting
      kanagawa-nvim # Neovim theme
      lightspeed-nvim # Navigation and range motions
      lsp_lines-nvim # Virtual line LSP diagnostics
      lspkind-nvim # Completion item kind symbols
      luasnip # Completion snippets engine
      nvim-cmp # Completion
      nvim-colorizer-lua # Colour code colorizer
      nvim-lspconfig # LSP default configurations
      plenary-nvim # Telescope-nvim dependency
      telescope-fzf-native-nvim # FZF sorter for telescope
      telescope-nvim # Fuzzy finder
      gitsigns-nvim # Git integration
      null-ls-nvim # LSP for formatters and linting
    ] ++ builtins.map (plugin: { inherit plugin; optional = true; }) [
      # Load optional plugins with `:packadd`
      playground # tree-sitter playground
    ];
    extraPackages = with pkgs; [
      ccls # C/C++ LSP
      clang-tools # C/C++ LSP and code formatter
      cppcheck # C/C++ code linter
      fd # Telescope finder
      nixfmt # Nix code formatter
      nodePackages.bash-language-server
      nodePackages.pyright # Python LSP
      rnix-lsp # Nix LSP
      statix # Nix code linter
      stylua # Lua code formatter
      luajitPackages.luacheck # Lua linter
      sumneko-lua-language-server # Lua LSP
      texlab # LaTeX LSP
      tree-sitter # Incremental parser
      valgrind # Memory debugging
      python3Packages.flake8 # Python linter
      python3Packages.black # Python code formatter
    ];
    extraConfig = ''
      " Home-Manager and NixOS currently do not support a pure Lua config
      " without a generated init.vim containing the runtimepath and packpath,
      " so we explicitly load init.lua 
      lua require('init')
    '';
  };

  # Link the Neovim lua configuration to ~/.config/nvim
  home.file.".config/nvim/lua".source = ./lua;
}

