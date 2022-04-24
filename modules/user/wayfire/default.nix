{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.wayland.windowManager.wayfire;

  allowedTypes = with types;
    either str (either int (either bool (either float (listOf (either float int)))));

  plugin = types.submodule {
    options = {
      package = mkOption {
        type = with types; nullOr package;
        default = null;
        example = literalExample "pkgs.wayfirePlugins.firedecor";
        description = ''
          Optional package containing one or more wayfire plugins not bundled
          with wayfire. If the plugin comes from a package, specify the package
          here so its provided plugins are properly loaded by Wayfire.
        '';
      };

      plugin = mkOption {
        type = types.str;
        example = "blur";
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
      example = literalExample "pkgs.wayfireApplications-unwrapped.wayfire";
      description = "Package to use";
    };

    extraSessionCommands = mkOption {
      type = with types; listOf str;
      default = [ ];
      description = ''
        Additional commands to run when launching
      '';
    };

    withGtkWrapper = mkEnableOption ''
      Whether to let Wayfire be aware of Gtk themes and settings
    '';

    settings = mkOption {
      type = types.submodule {
        freeformType = types.attrsOf allowedTypes;

        options.plugins = mkOption {
          type = types.listOf plugin;
          default = [ ];
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
    mergePluginSettings = ps:
      map (foldl recursiveUpdate { })
      (attrValues (groupBy (x: x.plugin) ps));
    plugins = mergePluginSettings cfg.settings.plugins;
    listToString = list: sep:
      concatStrings (intersperse sep (
        # Convert list elements to a sensible string representation
        map (generators.mkValueStringDefault { }) list));
    pluginsAttrs = let
      # Plugins without settings will not have a section generated for them
      pluginsWithSettings = filter (p: p.settings != { }) plugins;
    in listToAttrs (
        # Each plugin name becomes INI section name, and its `settings` attrs
        # become INI key-value pairs under that section name
        map (p:
          nameValuePair p.plugin (mapAttrs (_: value:
            # RGBA colour values are presented as `1.0 1.0 1.0 1.0` in the INI,
            # but the generator doesn't accept lists, so convert lists to strings
            if isList value then listToString value " " else value) p.settings))
        pluginsWithSettings);
    coreAttrs = {
      core = overrideExisting cfg.settings {
        plugins = listToString (map (p: if p.plugin != "input" then p.plugin else "") plugins) " ";
      };
    };
    settings = coreAttrs // pluginsAttrs;
    finalPackage = pkgs.callPackage ./wrapper.nix {
      wayfire = cfg.package;
      plugins = remove null (catAttrs "package" plugins);
      inherit (cfg) extraSessionCommands withGtkWrapper;
    };
  in mkIf cfg.enable {
    home.packages = [ finalPackage ];
    xdg.configFile."wayfire.ini".text = generators.toINI { } settings;
  };
}
