{ config, pkgs, ... }:

{
  # TODO: Refactor to `systemd.user.tmpfiles.settings` when
  # https://github.com/NixOS/nixpkgs/pull/317383 is merged.
  systemd.user.tmpfiles.rules = [
    # Link the Lua config for Neovim.
    "L+ %h/.config/nvim - - - - ${./nvim}"

    # Override the Neovim wrapper's .desktop file with our own less weird name.
    "L+ %h/.local/share/applications/nvim.desktop - - - - ${
      let
        drv = pkgs.runCommand "modify-nvim-desktop" {} ''
          mkdir -p $out
          substitute ${config.programs.neovim.finalPackage}/share/applications/nvim.desktop $out/nvim.desktop \
            --replace-warn 'Name=Neovim wrapper' 'Name=Neovim'
        '';
      in "${drv}/nvim.desktop"
    }"
  ];

  environment.variables = {
    EDITOR = "nvim";
    MANPAGER = "nvim -c 'set ft=man bt=nowrite noswapfile nobk shada=\\\"NONE\\\" ro noma' +Man! -o -";
  };

  programs.neovim = {
    enable = true;

    plugins = with pkgs.vimPlugins; [
      cmp-async-path
      cmp-buffer
      cmp-nvim-lsp
      cmp-nvim-lua
      cmp-under-comparator
      gitsigns-nvim
      hlargs-nvim
      indent-blankline-nvim
      nvim-cmp
      nvim-highlight-colors
      nvim-treesitter.withAllGrammars
      nvim-web-devicons
      telescope-nvim
      telescope-zf-native-nvim
      treesj
    ];

    extraPackages = with pkgs; [
      basedpyright
      clang-tools
      lua-language-server
      nixd
      ripgrep
      rust-analyzer
      zls
    ];
  };
}
