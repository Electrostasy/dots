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
      nixpkgs.lib.packagesFromDirectoryRecursive {
        callPackage = nixpkgs.legacyPackages.${system}.callPackage;
        directory = ./pkgs;
      });

    apps = forEachSystem (system: {
      nvim = {
        type = "app";
        program =
          let
            evaluatedModules = import "${nixpkgs}/nixos/lib/eval-config.nix" {
              inherit system;
              specialArgs = { inherit self; };

              modules = [
                self.outputs.nixosModules.neovim
                ./profiles/neovim
                ({ pkgs, ... }: {
                  nixpkgs.overlays = [ self.overlays.default ];

                  programs.neovim.plugins = [(
                    pkgs.vimUtils.buildVimPlugin {
                      name = "lua-config";
                      src = ./profiles/neovim/nvim;
                      postInstall = "mv $out/init.lua $out/plugin/init.lua";

                      # https://nixos.org/manual/nixpkgs/unstable/#testing-neovim-plugins-neovim-require-check
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
              runtimeInputs = with pkgs; [
                coreutils-full
                gnugrep
              ];
              text = builtins.readFile ./scripts/diff-closures.sh;
            };
          in
            nixpkgs.lib.getExe package;
        meta.description = "List added/removed packages and version updates between two closures.";
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
                gnugrep
                inotify-tools
                jq
                util-linux
              ];
              text = builtins.readFile ./scripts/is-cached.sh;
            };
          in
            nixpkgs.lib.getExe package;
        meta.description = "List cache availability for a derivation and its dependencies in https://cache.nixos.org.";
      };
    });

    nixosModules = {
      mpv = ./modules/mpv;
      neovim = ./modules/neovim;
      unfree = ./modules/unfree;
    };

    nixosConfigurations = nixpkgs.lib.mapAttrs (name: _:
      nixpkgs.lib.nixosSystem {
        specialArgs = { inherit self; };

        modules = [
          self.inputs.impermanence.nixosModules.default
          self.inputs.nixos-wsl.nixosModules.default
          self.inputs.sops-nix.nixosModules.default
          self.outputs.nixosModules.mpv
          self.outputs.nixosModules.neovim
          self.outputs.nixosModules.unfree
          { networking.hostName = name; }
          ./profiles/common
          ./hosts/${name}
        ];
      })
      (builtins.readDir ./hosts);

    checks.aarch64-linux = {
      deimosImage = self.outputs.nixosConfigurations.deimos.config.system.build.images.raw;
      lunaImage = self.outputs.nixosConfigurations.luna.config.system.build.images.raw;
      marsImage = self.outputs.nixosConfigurations.mars.config.system.build.images.raw;
      phobosImage = self.outputs.nixosConfigurations.phobos.config.system.build.images.raw;
    };
  };
}
