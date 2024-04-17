{ pkgs, ... }:

{
  # Configuration is written in Lua, copy it to the Nix store and symlink it
  # to ~/.config/nvim.
  systemd.tmpfiles.settings."10-neovim"."/home/electro/.config/nvim"."L+".argument = "${./nvim}";

  environment.variables = {
    EDITOR = "nvim";
    MANPAGER = "nvim -c 'set ft=man bt=nowrite noswapfile nobk shada=\\\"NONE\\\" ro noma' +Man! -o -";
  };

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

    extraPython3Packages = ps: with ps; [
      jedi-language-server
    ];

    extraPackages = with pkgs; [
      clang-tools
      lua-language-server
      nil
      ripgrep
      rust-analyzer
      wl-clipboard
      zls
    ];
  };
}