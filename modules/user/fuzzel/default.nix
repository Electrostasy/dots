{ config, pkgs, lib, ... }:

let
  cfg = config.programs.fuzzel;
  settingsFormat = pkgs.formats.ini { };
in

{
  options.programs.fuzzel = {
    enable = lib.mkEnableOption "fuzzel";

    package = lib.mkPackageOption pkgs "fuzzel" { };

    settings = lib.mkOption {
      type = lib.types.submodule { freeformType = settingsFormat.type; };
      default = { };
      description = ''
        Modular settings for fuzzel. See man fuzzel(1).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
    xdg.configFile."fuzzel/fuzzel.ini".source =
      settingsFormat.generate "fuzzel.ini" cfg.settings;
  };
}
