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
    inherit (nixpkgs) lib;

    forAllSystems = lib.genAttrs [
      "x86_64-linux"
      "aarch64-linux"
    ];

    /* Attribute set of all the packages packaged in this flake, a mapping of
       package names to their paths.
    */
    pkgs = lib.packagesFromDirectoryRecursive {
      callPackage = path: overrides: path;
      directory = ./pkgs;
    };
  in {
    overlays = {
      /* Generate an overlay from `pkgs` by handling the `callPackage` behaviour
         ourselves, making exceptions for namespaced package sets. We cannot reuse
         the definitions from `self.legacyPackages.${prev.system}`, as that would
         evaluate nixpkgs twice here (prev.system does not exist then).
      */
      default = final: prev:
        lib.mapAttrs
          (name: value:
            if lib.isAttrs value then
              if lib.hasAttrByPath [ name "overrideScope'" ] prev then
                # Namespaced package sets created with `lib.makeScope pkgs.newScope`.
                prev.${name}.overrideScope (final': prev':
                  lib.mapAttrs (name': value': final'.callPackage value' { }) value)
              else if lib.hasAttrByPath [ name "extend" ] prev then
                # Namespaced package sets created with `lib.makeExtensible`.
                prev.${name}.extend (final': prev':
                  lib.mapAttrs (name': value': final.callPackage value' { }) value)
              else
                # Namespaced package sets in regular attrsets.
                prev.${name} // value
            else
              final.callPackage value { })
          pkgs;

      ewfmount-fix = final: prev: {
        libewf = prev.libewf.overrideAttrs (oldAttrs: {
          # `ewfmount` depends on `fuse` to mount *.E01 forensic images.
          buildInputs = oldAttrs.buildInputs ++ [ prev.fuse ];
        });
      };

      unl0kr_3 = final: prev: {
        unl0kr = prev.unl0kr.overrideAttrs (finalAttrs: oldAttrs: {
          # Contains various fixes since 2.0.0.
          version = "3.0.0";
          src = oldAttrs.src.override {
            owner = "postmarketOS";
            repo = "buffybox";
            rev = finalAttrs.version;
            hash = "sha256-xmyh5F6sqD1sOPdocWJtucj4Y8yqbaHfF+a/XOcMk74=";
          };
          sourceRoot = "${finalAttrs.src.name}/unl0kr";
        });
      };
    };

    /* If I instead apply overlays on nixpkgs to generate this, namespaced package
       sets will bring in all of the packages under the namespace, therefore this
       method is much cleaner.
    */
    legacyPackages =
      forAllSystems (system:
        lib.mapAttrsRecursive
          (name: value: nixpkgs.legacyPackages.${system}.callPackage value { })
          pkgs);

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
                # Set the hostname here instead of repeating it for each host.
                { networking.hostName = name; }

                # Load the config for the host.
                ./hosts/${name}
              ];
            })
          hosts;

    nixosModules.unl0kr-settings = import ./modules/system/unl0kr-settings;

    homeManagerModules.wayfire = import ./modules/user/wayfire;
  };
}
