{
  description = ''
    NixOS configurations, out-of-tree/local packages, overlays and Home-Manager
    modules

    github:electrostasy/dots
  '';

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix = {
      url = "github:NixOS/nix/2.6-maintenance";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    rnix-lsp = {
      url = "github:nix-community/rnix-lsp";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    heirline-nvim = {
      url = "github:rebelot/heirline.nvim";
      flake = false;
    };
    filetype-nvim = {
      url = "github:nathom/filetype.nvim";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, nixos-hardware, ... }@inputs: {
    lib = import ./nixos/lib { inherit (nixpkgs) lib; inherit self; };

    packages = self.lib.extended.forAllSystems (system:
      let
        mkVimPlugin = pname:
          nixpkgs.legacyPackages.${system}.vimUtils.buildVimPluginFrom2Nix {
            inherit pname;
            src = inputs.${pname};
            version = inputs.${pname}.shortRev;
          };
        mkVimPlugins = pnames:
          builtins.listToAttrs (
            builtins.map (pname: self.lib.nameValuePair pname (mkVimPlugin pname)) pnames
          );
        mkPackage = nixpkgs.legacyPackages.${system}.callPackage;
      in
      mkVimPlugins [ "heirline-nvim" "filetype-nvim" ] // {
        firefox-custom = mkPackage ./pkgs/firefox { };
        gamescope = mkPackage ./pkgs/gamescope.nix { };
        wlr-spanbg = mkPackage ./pkgs/wlr-spanbg { };
        iosevka-nerdfonts = mkPackage ./pkgs/iosevka-nerdfonts.nix { };
      }
    );

    overlays = {
      vimPlugins = final: prev: {
        vimPlugins = prev.vimPlugins // {
          inherit (self.packages.${prev.system})
            heirline-nvim
            filetype-nvim;
        };
      };
      pkgs = final: prev: {
        inherit (self.packages.${prev.system})
          wlr-spanbg
          gamescope
          firefox-custom
          iosevka-nerdfonts;
      };
    };

    nixosModules = {
      home-manager.wayfire = import ./nixos/modules/home-manager/wayfire;
      unfree = import ./nixos/modules/unfree.nix;
    };

    nixosConfigurations = with self.lib.extended; {
      # Desktop workstation
      mars = nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/mars/configuration.nix
          ./hosts/mars/hardware-configuration.nix
          nixos-hardware.nixosModules.common-cpu-intel
          nixos-hardware.nixosModules.common-pc-ssd
          ./nixos/modules/profiles/dnscrypt-proxy2
          ./nixos/modules/profiles/flatpak
          ./nixos/modules/profiles/teamviewer
          ./nixos/modules/profiles/v4l2loopback
          self.nixosModules.unfree
        ] ++ forAllHomes [ "electro" ] [
          ./hosts/mars/displays.nix
          ./hosts/mars/home.nix
          ./modules/mpv.nix
          ./modules/neovim
          ./modules/nix-index.nix
          ./modules/wayfire
        ];
        overlays = builtins.attrValues self.overlays ++ [
          # Use the git/master builds
          (final: prev: {
            inherit (inputs.rnix-lsp.packages.${prev.system}) rnix-lsp;
          })
          (final: prev: rec {
            nixFlakes = inputs.nix.packages.${prev.system}.nix;
            nixUnstable = nixFlakes;
          })
        ];
      };

      # Raspberry Pi 4B
      phobos = nixosSystem {
        system = "aarch64-linux";
        modules = [
          ./hosts/phobos/configuration.nix
          ./hosts/phobos/hardware-configuration.nix
          ./hosts/phobos/nfs.nix
          nixos-hardware.nixosModules.raspberry-pi-4
        ];
        overlays = builtins.attrValues self.overlays;
      };

      # Raspberry Pi 3 (WIP)
      deimos = nixosSystem {
        system = "aarch64-linux";
        modules = [
          ./hosts/deimos/configuration.nix
        ];
        overlays = [
          # Cross-compilation of aarch64 ISO from x86_64-linux expects
          # unavailable kernel modules to be present since #78430:
          #   https://github.com/NixOS/nixpkgs/issues/126755#issuecomment-869149243
          # Tracking issue:
          #   https://github.com/NixOS/nixpkgs/issues/109280#issuecomment-973636212
          (final: prev: {
            makeModulesClosure = x:
              prev.makeModulesClosure (x // { allowMissing = true; });
          })
        ];
      };
    };
  };
}
