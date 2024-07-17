{
  description = ''
    Personal NixOS system configurations, modules and packages
  '';

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix/master";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-stable.follows = "nixpkgs";
      };
    };
    impermanence.url = "github:nix-community/impermanence/master";
  };

  outputs = { self, nixpkgs, ... }: let
    inherit (nixpkgs) lib;

    forEverySystem = lib.genAttrs lib.systems.flakeExposed;
    forEachSystem = lib.genAttrs [
      "x86_64-linux"
      "aarch64-linux"
    ];
  in {
    /*
      We rely on the behaviour of `lib.packagesFromDirectoryRecursive` here to
      return the name of the .nix file as the attribute name and the file path
      as value when a package.nix is absent.
    */
    overlays = lib.packagesFromDirectoryRecursive {
      callPackage = path: overrides: import path;
      directory = ./overlays;
    };

    /*
      If generated from the default overlay, namespaced package sets will bring
      in all of the packages under the namespace, making it unclear what packages
      are actually provided by this flake.
    */
    legacyPackages = forEachSystem (system:
      lib.packagesFromDirectoryRecursive {
        callPackage = nixpkgs.legacyPackages.${system}.callPackage;
        directory = ./pkgs;
      });

    packages = forEachSystem (system: {
      lunaImage = self.nixosConfigurations.luna.config.system.build.sdImage;
      marsImage = self.nixosConfigurations.mars.config.system.build.sdImage;
      phobosImage = self.nixosConfigurations.phobos.config.system.build.sdImage;
    });

    apps = forEverySystem (system: {
      nvim = {
        type = "app";
        program =
          let
            evaluatedModules = import "${nixpkgs}/nixos/lib/eval-config.nix" {
              specialArgs = { inherit self; };
              inherit system;

              modules = [
                ./profiles/common
                ./profiles/neovim
                ({ pkgs, ... }: {
                  # Add the Neovim configuration as a plugin.
                  programs.neovim.plugins = [(
                    pkgs.vimUtils.buildVimPlugin {
                      name = "lua-config";
                      src = ./profiles/neovim/nvim;
                      postInstall = ''
                        mv $out/init.lua $out/plugin/init.lua
                      '';
                    }
                  )];
                })
              ];
            };

            neovim = evaluatedModules.config.programs.neovim.finalPackage;
          in
            "${neovim}/bin/nvim";
      };
    });

    nixosModules = {
      mpv = import ./modules/mpv;
      neovim = import ./modules/neovim;
      unl0kr-settings = import ./modules/unl0kr-settings;
    };

    homeManagerModules.wayfire = import ./modules/user/wayfire;

    nixosConfigurations =
      let
        hosts =
          lib.filterAttrs
            (_: value: value == "directory")
            (builtins.readDir ./hosts);
      in
        lib.mapAttrs
          (name: _:
            lib.nixosSystem {
              # Inject this flake into the module system.
              specialArgs = { inherit self; };

              modules = [
                { networking.hostName = name; }
                ./hosts/${name}
                ./profiles/common
              ];
            })
          hosts;
  };
}
