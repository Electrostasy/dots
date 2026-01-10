{ config, pkgs, lib, ... }:

let
  cfg = config.programs.mpv;

  # Lists in mpv config are separated by comma.
  listToValue = lib.concatMapStringsSep "," toString;
  settingsFormat = pkgs.formats.keyValue { inherit listToValue; };
in

{
  options = {
    programs.mpv = {
      enable = lib.mkEnableOption "mpv";

      package = lib.mkPackageOption pkgs "mpv-unwrapped" { };
      finalPackage = lib.mkOption {
        type = lib.types.package;
        readOnly = true;
        description = "Resulting customized mpv package.";
      };

      settings = lib.mkOption {
        # In order to support mpv profiles, we need to allow nested attrsets.
        type = with lib.types; attrsOf (oneOf [
          # Top-level configuration for the global section of type:
          # "atom (null, bool, int, float or string) or a non-empty list of them"
          settingsFormat.type.nestedTypes.elemType
          # Top-level configuration for profiles (option groups) of type:
          # "attribute set of (atom (null, bool, int, float or string) or a non-empty list of them)"
          settingsFormat.type
        ]);
        default = {};
        description = "System-wide configuration for mpv.";
      };

      bindings = lib.mkOption {
        type = settingsFormat.type;
        default = {};
        description = "System-wide keybindings for mpv.";
      };

      scripts = lib.mkOption {
        type = with lib.types; listOf (either package (submodule {
          options = {
            script = lib.mkOption {
              type = lib.types.package;
              description = "The plugin to install.";
            };

            settings = lib.mkOption {
              type = lib.types.submodule {
                freeformType = settingsFormat.type;
              };
            };
          };
        }));

        description = "Scripts to install with optional configuration.";

        default = mpvScripts: [];
      };

      fonts = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "Customized fontconfig file for mpv.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.mpv.finalPackage = pkgs.mpv.override {
      mpv-unwrapped = cfg.package;
      scripts = map (s: if !lib.isDerivation s && lib.isAttrs s then s.script else s) cfg.scripts;

      # WARN: Without this, mpv will not detect any user-defined profiles in
      # the config for some reason.
      extraMakeWrapperArgs = [ "--add-flags" "--config-dir=/etc/mpv" ];
    };

    environment = {
      systemPackages = [ cfg.finalPackage ];

      etc = lib.mkMerge [
        (lib.optionalAttrs (cfg.settings != { }) {
          "mpv/mpv.conf".source =
            let
              format = pkgs.formats.iniWithGlobalSection { inherit listToValue; };
              filterGlobals = lib.filterAttrs (_: v: !lib.isAttrs v);
              filterProfiles = lib.filterAttrs (_: v: lib.isAttrs v);
            in
            format.generate "mpv.conf" {
              globalSection = filterGlobals cfg.settings;
              sections = filterProfiles cfg.settings;
            };
        })

        (lib.optionalAttrs (cfg.bindings != { }) {
          # input.conf does not use = as separator between key-value pairs and
          # we cannot change the separator in `pkgs.formats.keyValue`.
          "mpv/input.conf".source =
            let
              generator = with lib.generators; toKeyValue { mkKeyValue = mkKeyValueDefault { } " "; };
              bindings' = lib.mapAttrs (_: v: if lib.isList v then listToValue v else v) cfg.bindings;
            in
            pkgs.writeText "input.conf" (generator bindings');
        })

        (lib.optionalAttrs (cfg.fonts != "") {
          "mpv/fonts.conf".source = pkgs.writeText "fonts.conf" cfg.fonts;
        })

        # For each script accompanied by configuration, generate a .conf file
        # using the script name.
        (let
          mkScriptConfig = scriptName: settings:
            lib.nameValuePair
              "mpv/script-opts/${scriptName}.conf"
              { source = settingsFormat.generate "${scriptName}.conf" settings; };

          scriptsWithSettings = lib.filter (s: !lib.isDerivation s && lib.isAttrs s) cfg.scripts;
        in
          builtins.listToAttrs
            (map
              (s:
                mkScriptConfig s.script.passthru.scriptName s.settings)
              scriptsWithSettings))
      ];
    };
  };
}
