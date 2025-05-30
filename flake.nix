{
  description = ''
    Personal NixOS system configurations, modules and packages
  '';

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";

    impermanence.url = "github:nix-community/impermanence/master";

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }: let
    forEachSystem = nixpkgs.lib.genAttrs [
      "aarch64-darwin"
      "aarch64-linux"
      "x86_64-darwin"
      "x86_64-linux"
    ];
  in {
    overlays = nixpkgs.lib.packagesFromDirectoryRecursive {
      callPackage = path: overrides: import path;
      directory = ./overlays;
    };

    legacyPackages = forEachSystem (system:
      let
        packages = nixpkgs.lib.packagesFromDirectoryRecursive {
          callPackage = nixpkgs.lib.callPackageWith (nixpkgs.legacyPackages.${system} // packages);
          directory = ./pkgs;
        };
      in
        packages);

    apps = forEachSystem (system: {
      nvim = {
        type = "app";
        program =
          let
            evaluatedModules = import "${nixpkgs}/nixos/lib/eval-config.nix" {
              inherit system;

              modules = [
                self.outputs.nixosModules.neovim
                { _module.args.flake = self; }
                ./profiles/neovim
                ({ pkgs, flake, ... }: {
                  nixpkgs.overlays = [ flake.overlays.default ];

                  programs.neovim.plugins = [(
                    pkgs.vimUtils.buildVimPlugin {
                      name = "lua-config";
                      src = ./profiles/neovim/nvim;
                      postInstall = "mv $out/init.lua $out/plugin/init.lua";
                      doCheck = false;
                    }
                  )];
                })
              ];
            };
          in
            nixpkgs.lib.getExe evaluatedModules.config.programs.neovim.finalPackage;
        meta.description = "Self-contained Neovim environment";
      };

      diff-closures = {
        type = "app";
        program =
          let
            pkgs = nixpkgs.legacyPackages.${system};
            package = pkgs.writeShellApplication {
              name = "diff-closures";
              runtimeInputs = [ pkgs.jq ];
              text = ''
                if [[ $# -eq 0 ]]; then
                  set -- "/run/current-system" "/etc/nixos#nixosConfigurations.\"$HOSTNAME\".config.system.build.toplevel"
                elif ! nix path-info --derivation "$1" "$2" &> /dev/null; then
                  echo 'Error: arguments must evaluate to Nix derivations!'
                  exit 1
                fi

                jq -rf ${./scripts/diff-closures.jq} -s <(nix derivation show -r "$1") <(nix derivation show -r "$2")
              '';
            };
          in
            nixpkgs.lib.getExe package;
        meta.description = "Show what packages and versions changed between two closures.";
      };

      is-cached = {
        type = "app";
        program =
          let
            pkgs = nixpkgs.legacyPackages.${system};
            package = pkgs.writeShellApplication {
              name = "is-cached";
              runtimeInputs = with pkgs; [
                coreutils-full
                curl
              ];
              text = builtins.readFile ./scripts/is-cached.sh;
            };
          in
            nixpkgs.lib.getExe package;
        meta.description = "List cache availability for a derivation and its dependencies in https://cache.nixos.org.";
      };
    });

    nixosModules = {
      mpv = ./modules/mpv.nix;
      neovim = ./modules/neovim.nix;
      unfree = ./modules/unfree.nix;
      zswap = ./modules/zswap.nix;
    };

    nixosConfigurations = nixpkgs.lib.mapAttrs (name: _:
      nixpkgs.lib.nixosSystem {
        modules = [
          self.inputs.impermanence.nixosModules.default
          self.inputs.nixos-wsl.nixosModules.default
          self.inputs.sops-nix.nixosModules.default
          self.outputs.nixosModules.mpv
          self.outputs.nixosModules.neovim
          self.outputs.nixosModules.unfree
          self.outputs.nixosModules.zswap

          # Allow modules to refer to this flake by argument.
          { _module.args.flake = self; }

          ./profiles/common
          { networking.hostName = name; }
          ./hosts/${name}
        ];
      })
      (builtins.readDir ./hosts);

    checks.aarch64-linux = {
      atlas-image = self.outputs.nixosConfigurations.atlas.config.system.build.images.raw;
      deimos-image = self.outputs.nixosConfigurations.deimos.config.system.build.images.raw;
      hyperion-image = self.outputs.nixosConfigurations.hyperion.config.system.build.images.raw;
      luna-image = self.outputs.nixosConfigurations.luna.config.system.build.images.raw;
      mars-image = self.outputs.nixosConfigurations.mars.config.system.build.images.raw;
      phobos-image = self.outputs.nixosConfigurations.phobos.config.system.build.images.raw;
    };
  };
}
