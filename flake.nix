{
  description = ''
    Personal NixOS system configurations, modules and packages
  '';

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    inherit (nixpkgs.lib) genAttrs fix composeManyExtensions nixosSystem;
    forAllSystems = genAttrs [
      "x86_64-linux"
      "aarch64-linux"
    ];
  in {
    overlays = {
      default = import ./packages;
      customisations = final: prev: {
        libewf = prev.libewf.overrideAttrs {
          # `ewfmount` depends on `fuse` to mount *.E01 forensic images.
          buildInputs = [ prev.fuse ];
        };
      };
    };

    legacyPackages = forAllSystems (system:
      fix
        (composeManyExtensions (builtins.attrValues self.overlays))
        nixpkgs.legacyPackages.${system});

    packages = forAllSystems (_: {
      lunaImage = self.nixosConfigurations.luna.config.system.build.sdImage;
      marsImage = self.nixosConfigurations.mars.config.system.build.sdImage;
      phobosImage = self.nixosConfigurations.phobos.config.system.build.sdImage;
    });

    nixosConfigurations =
      builtins.mapAttrs
        (_: v: nixosSystem { specialArgs.self = self; modules = [ v ]; })
        {
          ceres = ./hosts/ceres;
          eris = ./hosts/eris;
          kepler = ./hosts/kepler;
          luna = ./hosts/luna;
          mars = ./hosts/mars;
          phobos = ./hosts/phobos;
          terra = ./hosts/terra;
          venus = ./hosts/venus;
        };

    homeManagerModules.wayfire = import ./modules/user/wayfire;
  };
}
