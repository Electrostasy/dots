{ pkgs, lib, ... }:

{
  preservation.preserveAt."/persist/state".users.electro.directories = [
    ".local/state/nvim"
    ".local/share/nvim"
  ];

  # TODO: Refactor to `systemd.user.tmpfiles.settings` when
  # https://github.com/NixOS/nixpkgs/pull/317383 is merged.
  systemd.user.tmpfiles.rules = [
    # Link the Lua config for Neovim.
    "L+ %h/.config/nvim - - - - ${./nvim}"
  ];

  xdg.mime.defaultApplications."text/plain" = "nvim.desktop";

  environment.systemPackages = with pkgs; [
    fd
    ripgrep
  ];

  environment.variables = {
    EDITOR = "nvim";
    MANPAGER = "nvim +Man!";
  };

  programs.neovim = {
    enable = true;

    plugins = with pkgs.vimPlugins; [
      blink-cmp
      blink-indent
      gitsigns-nvim
      hlargs-nvim
      nvim-highlight-colors
      nvim-web-devicons
      treesj

      # Exclude parsers already bundled with Neovim:
      # https://neovim.io/doc/user/treesitter.html#treesitter-parsers
      (nvim-treesitter.withPlugins (plugins: lib.pipe plugins [
        (lib.filterAttrs (_: value: lib.pipe value [
          lib.isDerivation

          (plugin: with plugins; !lib.elem plugin [
            tree-sitter-c
            tree-sitter-lua
            tree-sitter-markdown
            tree-sitter-query
            tree-sitter-vim
            tree-sitter-vimdoc
          ])
        ]))

        lib.attrValues
      ]))
    ];

    extraPackages = with pkgs; [
      emmylua-ls
      nixd
    ];
  };
}
