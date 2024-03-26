{ config, pkgs, lib, ... }:

let
  cfg = config.boot.initrd.unl0kr;
  settingsFormat = pkgs.formats.ini { };
in
{
  options = {
    boot.initrd.unl0kr = {
      settings = lib.mkOption {
        description = ''
          Configuration for `unl0kr`.

          See `unl0kr.conf(5)` for supported values.
        '';

        type = lib.types.submodule {
          freeformType = settingsFormat.type;
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    boot.initrd.systemd.contents."/etc/unl0kr.conf".source =
      settingsFormat.generate "unl0kr.conf" cfg.settings;
  };
}
