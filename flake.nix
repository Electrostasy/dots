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
    inherit (nixpkgs) lib;

    forEachSystem = lib.genAttrs [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  in {
    overlays = lib.packagesFromDirectoryRecursive {
      callPackage = path: overrides: import path;
      directory = ./overlays;
    };

    legacyPackages = forEachSystem (system:
      lib.packagesFromDirectoryRecursive {
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
            lib.getExe evaluatedModules.config.programs.neovim.finalPackage;
          meta.description = "Self-contained Neovim environment";
      };
    });

    nixosModules = {
      mpv = ./modules/mpv;
      neovim = ./modules/neovim;
      unfree = ./modules/unfree;
    };

    nixosConfigurations = lib.mapAttrs (name: _:
      lib.nixosSystem {
        specialArgs = { inherit self; };

        modules =
          lib.attrValues self.outputs.nixosModules
          ++ lib.mapAttrsToList (n: v: v.nixosModules.default or v.nixosModules.${n} or {}) self.inputs
          ++ [
            ./profiles/common
            ./hosts/${name}
            { networking.hostName = name; }
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
