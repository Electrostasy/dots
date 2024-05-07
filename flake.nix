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

    forAllSystems = lib.genAttrs [
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
      Attribute set of all the packages packaged in this flake, a mapping of
      package names to their derivations.

      If generated from the default overlay, namespaced package sets will bring
      in all of the packages under the namespace, making it unclear what packages
      are actually provided by this flake.
    */
    legacyPackages = forAllSystems (system:
      lib.packagesFromDirectoryRecursive {
        callPackage = nixpkgs.legacyPackages.${system}.callPackage;
        directory = ./pkgs;
      });

    packages =
      forAllSystems (system: {
        lunaImage = self.nixosConfigurations.luna.config.system.build.sdImage;
        marsImage = self.nixosConfigurations.mars.config.system.build.sdImage;
        phobosImage = self.nixosConfigurations.phobos.config.system.build.sdImage;
      });

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

    nixosModules = {
      mpv = import ./modules/mpv;

      neovim = import ./modules/neovim;

      unl0kr-settings = import ./modules/unl0kr-settings;
    };

    homeManagerModules.wayfire = import ./modules/user/wayfire;
  };
}
