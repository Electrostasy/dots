{ pkgs, lib, ... }:

{
  preservation.preserveAt."/persist/state".users.electro.directories = [
    ".local/state/nvim"
    ".local/share/nvim"
  ];

  environment.systemPackages = [
    (pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped {
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

      wrapperArgs = "--suffix PATH : ${lib.makeBinPath [
        pkgs.emmylua-ls
        pkgs.nixd
        pkgs.fd
      ]}";

      # If this is enabled, Neovim cannot load configuration from /etc/xdg/nvim
      # or ~/.config/nvim.
      wrapRc = false;
    })

    # Replaces 'Neovim wrapper' with 'Neovim' in the nvim.desktop because the
    # wrapper does not allow us to configure it.
    (lib.hiPrio (pkgs.runCommand "hide-neovim-wrapper-desktop" { } ''
      mkdir -p "$out/share/applications"
      cp ${pkgs.neovim-unwrapped}/share/applications/nvim.desktop "$out/share/applications/nvim.desktop"
    ''))
  ];

  environment.etc."xdg/nvim".source = ./nvim;

  environment.variables = {
    EDITOR = "nvim";
    MANPAGER = "nvim +Man!";
  };

  xdg.mime.defaultApplications."text/plain" = "nvim.desktop";
}
