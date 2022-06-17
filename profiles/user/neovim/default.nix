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
      (nvim-cmp.overrideAttrs (old: {
        src = pkgs.fetchFromGitHub {
          owner = "hrsh7th";
          repo = "nvim-cmp";
          rev = "df6734aa018d6feb4d76ba6bda94b1aeac2b378a";
          sha256 = "sha256-vWvfa1a9FcVqs5y6qB8ugHGYxcc2vw2iceiCfq5i0UQ=";
        };
      }))
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
    set EDITOR nvim
  '';
}
