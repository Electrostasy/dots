{ config, lib, ... }:

# The traditional way of allowing certain unfree packages is by:
# `nixpkgs.config.allowUnfreePredicate`

# however, as they are provided by a function, supplying a list of package
# names from different modules overrides the function each time. This wrapper
# module allows to specify packages directly from different modules, and
# evaluate the function.

with lib;

let cfg = config.nixpkgs;

in

{
  options = {
    nixpkgs = {
      allowedUnfreePackages = mkOption {
        type = with types; listOf package;
        default = [];
        example = literalExpression "[ pkgs.steam ]";
      };
    };
  };
  
  config.nixpkgs.config = {
    allowUnfreePredicate = pkg:
      # If we don't specifically use `lib.getName`, some packages will still
      # fail to be detected by `builtins.elem`
      builtins.elem (getName pkg) (builtins.map getName cfg.allowedUnfreePackages);
  };
}

