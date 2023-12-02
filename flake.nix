{
  description = ''
    Personal NixOS system configurations, modules and packages
  '';

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
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
    inherit (nixpkgs.lib) genAttrs fix composeManyExtensions mapAttrs;

    forAllSystems = genAttrs [ "x86_64-linux" "aarch64-linux" ];

    nixosSystem = args: nixpkgs.lib.nixosSystem (args // {
      specialArgs = args.specialArgs or { } // { inherit self; };
    });
  in {
    overlays = {
      default = import ./packages;
      customisations = final: prev: {
        libewf = prev.libewf.overrideAttrs (_: {
          # `ewfmount` depends on `fuse` to mount *.E01 forensic images.
          buildInputs = [ prev.fuse ];
        });
      };
    };

    legacyPackages = forAllSystems (system:
      fix
        (composeManyExtensions (builtins.attrValues self.overlays))
        nixpkgs.legacyPackages.${system});

    packages = forAllSystems (system: {
      marsImage = self.nixosConfigurations.mars.config.system.build.sdImage;
    });

    nixosConfigurations = mapAttrs (_: nixosSystem) {
      ceres.modules = [ ./hosts/ceres ];
      eris.modules = [ ./hosts/eris ];
      kepler.modules = [ ./hosts/kepler ];
      mars.modules = [ ./hosts/mars ];
      phobos.modules = [ ./hosts/phobos ];
      terra.modules = [ ./hosts/terra ];
      venus.modules = [ ./hosts/venus ];
    };

    homeManagerModules.wayfire = import ./modules/user/wayfire;
  };
}
