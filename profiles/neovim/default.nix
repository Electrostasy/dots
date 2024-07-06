{ config, pkgs, ... }:

{
  systemd.tmpfiles.settings."10-neovim" = {
    # Link the Lua config for Neovim.
    "/home/electro/.config/nvim"."L+".argument = "${./nvim}";

    # Override the Neovim wrapper's .desktop file with our own less weird name.
    "/home/electro/.local/share/applications/nvim.desktop"."L+".argument =
      let
        drv = pkgs.runCommand "modify-nvim-desktop" {} ''
          mkdir -p $out
          substitute ${config.programs.neovim.finalPackage}/share/applications/nvim.desktop $out/nvim.desktop \
            --replace-warn 'Name=Neovim wrapper' 'Name=Neovim'
        '';
      in "${drv}/nvim.desktop";
  };

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
