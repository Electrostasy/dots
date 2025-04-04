{
  description = ''
    Personal NixOS system configurations, modules and packages
  '';

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

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
              text = builtins.readFile ./scripts/diff-closures.sh;
            };
          in
            nixpkgs.lib.getExe package;
        meta.description = "Show what packages and versions were added and removed between two closures.";
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

          # Allow modules to refer to this flake by argument.
          { _module.args.flake = self; }

          ./profiles/common
          { networking.hostName = name; }
          ./hosts/${name}
        ];
      })
      (builtins.readDir ./hosts);

    checks.aarch64-linux = {
      deimos-image = self.outputs.nixosConfigurations.deimos.config.system.build.images.raw;
      luna-image = self.outputs.nixosConfigurations.luna.config.system.build.images.raw;
      mars-image = self.outputs.nixosConfigurations.mars.config.system.build.images.raw;
      phobos-image = self.outputs.nixosConfigurations.phobos.config.system.build.images.raw;
    };
  };
}
