{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.wayland.windowManager.wayfire;

  allowedTypes = with types;
    either str (either int (either bool (either float (listOf float))));

  plugin = types.submodule {
    options = {
      package = mkOption {
        type = with types; nullOr package;
        default = null;
        example = literalExample "pkgs.swayfire";
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
      example =
        literalExample "pkgs.unstable.wayfireApplications-unwrapped.wayfire";
      description = "Package to use";
    };

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
    pluginsAttrs = listToAttrs (
      # Each plugin name becomes INI section name, and its `settings` attrs
      # become INI key-value pairs under that section name
      map (p:
        nameValuePair p.plugin (mapAttrs (_: value:
          # RGBA colour values are presented as `1.0 1.0 1.0 1.0` in the INI,
          # but the generator doesn't accept lists, so convert lists to strings
          if isList value then listToString value " " else value) p.settings))
      plugins);
    coreAttrs = {
      core = overrideExisting cfg.settings {
        plugins = listToString (map (p: p.plugin) plugins) " \\ \n  ";
      };
    };
    settings = coreAttrs // pluginsAttrs;
    # The current `wayfireApplications.withPlugins` interface for wrapping wayfire
    # plugins does not allow using a different wayfire derivation, so we call
    # the wrapper `wrapWayfireApplication` directly as it is called in Nixpkgs at
    # nixpkgs/applications/window-managers/wayfire/applications.nix#L17 to wrap
    # Wayfire with a specified list of derivations (plugins)
    finalPackage = /* pkgs.wayfireApplications.wrapWayfireApplication */ (pkgs.callPackage ./wrapper.nix { }) cfg.package
      (_: remove null (unique (catAttrs "package" plugins)));
  in mkIf cfg.enable {
    home = {
      packages = [ finalPackage ];
      sessionVariables.XDG_CURRENT_DESKTOP = "wayfire";
    };
    xdg.configFile."wayfire.ini".text = generators.toINI { } settings;
  };
}
