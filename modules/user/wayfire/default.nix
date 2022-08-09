{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.wayland.windowManager.wayfire;

  allowedTypes = with types;
    oneOf [ str int bool float (listOf (oneOf [ float int ])) ];

  # NOTE: Consumers of this module may use `lib.mkOrder 0` for plugin
  # configuration defined in multiple modules to control order of
  # `lib.types.listOf` merge (list concatenation) behaviour. Plugin
  # configuration sharing a common `plugin` attribute will be merged.
  # TODO: Allow using `lib.mkOverride` on specific settings values
  plugin = types.submodule {
    options = {
      package = mkOption {
        type = with types; nullOr package;
        default = null;
        description = ''
          Optional package containing one or more wayfire plugins not bundled
          with wayfire. If the plugin comes from a package, specify the package
          here so its provided plugins are properly loaded by Wayfire.
        '';
      };

      plugin = mkOption {
        type = types.str;
        description = ''
          Name of the plugin. Name can be obtained from the plugin documentation
          and/or the metadata XML files.
        '';
      };

      settings = mkOption {
        type = types.submodule { freeformType = types.attrsOf allowedTypes; };
        default = { };
        description = ''
          Key-value style attribute set of settings for an individual
          plugin. Valid values: int, float, bool, str, or list or floats.
          Nested attribute sets are not valid.
        '';
      };
    };
  };
in {
  options.wayland.windowManager.wayfire = {
    enable = mkEnableOption "Wayfire 3D wayland compositor";

    package = mkOption {
      type = types.package;
      default = pkgs.wayfireApplications-unwrapped.wayfire;
      example = literalExpression "pkgs.wayfireApplications-unwrapped.wayfire";
      description = "Package to use";
    };

    extraSessionCommands = mkOption {
      type = with types; listOf str;
      default = [ ];
      example = literalExpression ''[ "export NIXOS_OZONE_WL=1" ]'';
      description = "Additional commands to run when launching";
    };

    withGtkWrapper = mkEnableOption "Make Wayfire aware of Gtk themes and settings";

    settings = mkOption {
      type = types.submodule {
        freeformType = types.attrsOf allowedTypes;

        options.plugins = mkOption {
          type = types.listOf plugin;
          default = [ ];
          example = literalExpression ''
            [
              { plugin = "move"; settings.activate = "<super> BTN_LEFT"; }
              { plugin = "place"; settings.mode = "cascade"; }
              { package = pkgs.wayfirePlugins.firedecor;
                plugin = "firedecor";
                settings = {
                  layout = "-";
                  border_size = 8;
                  active_border = [ 0.121569 0.121569 0.156863 1.000000 ];
                  inactive_border = [ 0.121569 0.121569 0.156863 1.000000 ];
                };
              }
            ]
          '';
          description = "List of plugins to enable and configure";
        };
      };
      description = ''
        Configuration options as defined in
        https://github.com/WayfireWM/wayfire/wiki/Configuration.
        Options in the #core section are implied as top-level attributes
        of the `settings` set.
      '';
    };
  };

  config = let
    # Merge plugin config if defined multiple times
    mergedPlugins = builtins.attrValues (
      mapAttrs
        (_: foldl (a: b: recursiveUpdate b a) { })
        (groupBy (x: x.plugin) cfg.settings.plugins)
    );

    # Convert lists to strings for generators.toINI
    listToString = list:
      concatStrings (intersperse " " (map (generators.mkValueStringDefault { }) list));

    pluginsSettings = let
      mkSettings = p: let
        name = p.plugin;
        content = mapAttrs (_: v: if isList v then listToString v else v) p.settings;
      in nameValuePair name content;
      pluginsWithSettings = filter (p: p.settings != { }) mergedPlugins;
    in listToAttrs (map mkSettings pluginsWithSettings);

    # Configuration not part of any plugins goes into the `core` attrset,
    # and each plugin will have its own attrset with corresponding settings
    settings = pluginsSettings // {
      core = overrideExisting cfg.settings {
        # `input` and `output` are `core` plugins and are loaded by default,
        # it is unnecessary to put them in the plugins list
        plugins = let
          filterFn = p: let
            notInput = p.plugin != "input";
            notInputDevice = (builtins.match "(input-device:.*)" p.plugin) == null;
            notOutput = (builtins.match "(output:.*)" p.plugin) == null;
          in if notInput && notInputDevice && notOutput then p.plugin else "";
        in listToString (map filterFn mergedPlugins);
      };
    };

    finalPackage = pkgs.callPackage ./wrapper.nix {
      wayfire = cfg.package;
      plugins = remove null (catAttrs "package" mergedPlugins);
      inherit (cfg) extraSessionCommands withGtkWrapper;
    };

  in mkIf cfg.enable {
    home.packages = [ finalPackage ];
    xdg.configFile."wayfire.ini".text = generators.toINI { } settings;
  };
}
