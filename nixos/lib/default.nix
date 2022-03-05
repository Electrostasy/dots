{ lib, self, ... }:

let
  homeManager = self.inputs.home-manager.nixosModule;
  homeGlobal = { config, ... }: {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      sharedModules = builtins.attrValues self.outputs.nixosModules.home-manager;
    };
  };
  nixFlakes = { config, pkgs, ... }: {
    nix = {
      package = pkgs.nixFlakes;
      extraOptions = "experimental-features = nix-command flakes";
      # Setting $NIX_PATH to Flake-provided nixpkgs allows repl and other
      # channel-dependent programs to use the correct nixpkgs
      settings.nix-path = [ "nixpkgs=${self.inputs.nixpkgs}" ];
    };
  };
  overlay = final: prev: {
    extended = {
      colour = import ./colour.nix { lib = final; };

      # Turn a list of Home-manager modules into a list of NixOS modules
      # by applying them to each user in `users`
      forAllHomes = users: modules:
        let
          mkHomeModule = user: { home-manager, ... }: {
            home-manager.users.${user}.imports = modules;
          };
          homes = builtins.map mkHomeModule users;
        in [ homeManager homeGlobal ] ++ homes;

      forAllSystems = with prev; genAttrs (systems.supported.tier1 ++ systems.supported.tier2);

      nixosSystem = { modules,  ... }@args:
        let
          overlaysModule = { config, ... }: {
            nixpkgs.overlays = args.overlays or [];
          };
          gitRevModule = { config, lib, ... }: {
            system.configurationRevision = lib.mkIf (self ? rev) self.rev;
          };
          # `makeOverridable` allows us to build images and run VMs with configs
          # defined in `nixosConfigurations` in flake.nix:
          # https://github.com/NixOS/nixpkgs/pull/101475
          # https://github.com/nix-community/nixos-generators/issues/110#issuecomment-895963028
          overridableSystem = with prev; makeOverridable nixosSystem;
          configuration = prev.filterAttrs (n: _: n != "overlays") args // {
            modules = [ nixFlakes overlaysModule gitRevModule ] ++ modules;
            # Inherit extended lib and access to flake attrs
            specialArgs = { lib = final; flake = self; } // args.specialArgs or { };
          };
        in overridableSystem configuration;
    };
  };

in

lib.extend overlay

