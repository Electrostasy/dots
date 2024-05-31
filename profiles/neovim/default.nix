{ pkgs, ... }:

{
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
      cmp-nvim-lsp
      cmp-nvim-lua
      cmp-path
      cmp-under-comparator
      nvim-cmp

      # Visual improvements.
      hlargs-nvim
      indent-blankline-nvim
      lsp_lines-nvim
      nvim-highlight-colors
      nvim-treesitter.withAllGrammars
      nvim-web-devicons

      # Functionality.
      gitsigns-nvim
      telescope-zf-native-nvim
      telescope-nvim
      treesj
    ];

    extraPackages = with pkgs; [
      basedpyright
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
