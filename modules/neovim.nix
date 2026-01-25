{ config, pkgs, lib, ... }:

/*
  This module configures Neovim in much the same way that it is handled in
  home-manager. In nixpkgs, neovim is wrapped to use a specific config file
  with the -u flag, which makes it harder to use the Lua config from
  ~/.config/nvim. We do not need support for inline configuration as it is messy.
*/

let
  cfg = config.programs.neovim;
in

{
  disabledModules = [ "programs/neovim.nix" ];

  options = {
    programs.neovim = {
      enable = lib.mkEnableOption "neovim";

      package = lib.mkPackageOption pkgs "neovim-unwrapped" { };

      finalPackage = lib.mkOption {
        type = lib.types.package;
        readOnly = true;
        description = "Resulting customized neovim package.";
      };

      viAlias = lib.mkEnableOption "`vi` alias for `nvim`";
      vimAlias = lib.mkEnableOption "`vim` alias for `nvim`";
      vimdiffAlias = lib.mkEnableOption "`vimdiff` alias for `nvim -d`";

      withNodeJs = lib.mkEnableOption "support for Node plugins";
      withRuby = lib.mkEnableOption "support for Ruby plugins";
      withPython3 = lib.mkEnableOption "support for Python 3 plugins";

      extraPython3Packages = lib.mkOption {
        type = with lib.types; functionTo (listOf package);
        default = _: [];
        description = "Extra Python 3 packages required for plugins to work.";
      };

      # TODO: I don't need this option but maybe it should be added?
      # extraLuaPackages = lib.mkOption {
      #   type = with lib.types; functionTo (listOf packages);
      #   default = _: [];
      #   description = "Extra Lua packages required for plugins to work.";
      # };

      plugins = lib.mkOption {
        type = with lib.types; listOf (either package (submodule {
          options = {
            plugin = lib.mkOption {
              type = lib.types.package;
              description = "The plugin to install.";
            };

            optional = lib.mkEnableOption "the plugin manually with :packadd";
          };
        }));
        default = [];
        description = "List of vim plugins to install.";
      };

      extraPackages = lib.mkOption {
        type = with lib.types; listOf package;
        default = [];
        description = "Extra packages available to neovim.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      cfg.finalPackage

      # Replace 'Neovim wrapper' with 'Neovim', inspired by:
      # https://discourse.nixos.org/t/make-neovim-wrapper-desktop-optional/37597/3#alternatives-3
      (lib.hiPrio (pkgs.runCommand "hide-neovim-wrapper-desktop" { } ''
        mkdir -p "$out/share/applications"
        cp ${config.programs.neovim.package}/share/applications/nvim.desktop "$out/share/applications/nvim.desktop"
      ''))
    ];

    programs.neovim.finalPackage =
      let
        neovimConfig = pkgs.neovimUtils.makeNeovimConfig {
          inherit (cfg) withPython3 extraPython3Packages withRuby withNodeJs plugins viAlias vimAlias vimdiffAlias;
        };
      in
        pkgs.wrapNeovimUnstable cfg.package (neovimConfig // {
          wrapperArgs = lib.concatStringsSep " " [
            (lib.escapeShellArgs neovimConfig.wrapperArgs)
            "--suffix PATH : ${lib.makeBinPath cfg.extraPackages}"
          ];
          wrapRc = false;
        });
  };
}
