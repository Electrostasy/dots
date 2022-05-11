{ self, ... }:

let
  overlay = final: prev: {
    extended = {
      # Turn a list of Home-manager modules into a list of NixOS modules
      # by applying them to each user in `users`
      forAllHomes = users: modules:
        let
          mkHomeModule = user: { home-manager, ... }: {
            home-manager.users.${user}.imports = modules;
          };
          homes = builtins.map mkHomeModule users;
        in [
          self.inputs.home-manager.nixosModule
          ({ config, ... }: {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              sharedModules = builtins.attrValues self.outputs.nixosModules.home-manager;
            };
          })
        ] ++ homes;

      forAllSystems = with prev; genAttrs (systems.supported.tier1 ++ systems.supported.tier2);

      nixosSystem = { system, modules, ... }@args:
        let
          # `makeOverridable` allows us to build images and run VMs with configs
          # defined in `nixosConfigurations` in flake.nix:
          # https://github.com/NixOS/nixpkgs/pull/101475
          # https://github.com/nix-community/nixos-generators/issues/110#issuecomment-895963028
          overridableSystem = with prev; makeOverridable nixosSystem;
          configuration = prev.filterAttrs (n: _: n != "overlays") args // {
            modules = [
              # Nix/Nixpkgs common configuration
              {
                nixpkgs.overlays = args.overlays or [];
                system.configurationRevision = prev.mkIf (self ? rev) self.rev;

                nix = {
                  package = self.inputs.nixpkgs.legacyPackages.${system}.nixFlakes;
                  extraOptions = "experimental-features = nix-command flakes";

                  # Setting $NIX_PATH to Flake-provided nixpkgs allows repl and other
                  # channel-dependent programs to use the correct nixpkgs
                  settings.nix-path = [ "nixpkgs=${self.inputs.nixpkgs}" ];
                  registry.nixpkgs = {
                    from = { type = "indirect"; id = "nixpkgs"; };
                    flake = self.inputs.nixpkgs;
                  };
                };
              }

              # Secrets management
              {
                fileSystems."/var/lib/sops-nix" = {
                  device = "/state/var/lib/sops-nix";
                  fsType = "none";
                  options = [ "bind" ];
                  depends = [ "/state" ];
                  neededForBoot = true;
                };

                environment = {
                  sessionVariables.SOPS_AGE_KEY_FILE = "/var/lib/sops-nix/keys.txt";

                  systemPackages =
                    with self.inputs.nixpkgs.legacyPackages.${system};
                    [ sops rage sequoia ];
                };

                sops = {
                  age = {
                    keyFile = "/var/lib/sops-nix/keys.txt";
                    sshKeyPaths = [];
                  };
                  gnupg.sshKeyPaths = [];
                };
              }
            ] ++ modules;
            # Inherit extended lib and access to flake attrs
            specialArgs = { lib = final; flake = self; } // args.specialArgs or { };
          };
        in overridableSystem configuration;
    };
  };

in

self.inputs.nixpkgs.lib.extend overlay
