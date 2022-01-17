{
  description = ''
    NixOS configurations, out-of-tree/local packages, overlays and Home-Manager
    modules

    github:electrostasy/dots
  '';

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixpkgs-unstable;
    home-manager = {
      url = github:nix-community/home-manager/master;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix = {
      url = github:NixOS/nix/b4f250417ab64f237c8b51439fe1f427193ab23b;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = github:NixOS/nixos-hardware/master;

    rnix-lsp = {
      url = github:nix-community/rnix-lsp;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    heirline-nvim = {
      url = github:rebelot/heirline.nvim;
      flake = false;
    };
    filetype-nvim = {
      url = github:nathom/filetype.nvim;
      flake = false;
    };
    lsp_lines-nvim = {
      url = "git+https://git.sr.ht/~whynothugo/lsp_lines.nvim?ref=main";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, nixos-hardware, ... }@inputs: {
    lib = import ./lib { inherit (nixpkgs) lib; inherit self; };

    packages = self.lib.extended.forAllSystems (system:
      let
        # This is probably a bit too clever
        mkVimPlugins = pnames:
          builtins.listToAttrs (
            builtins.map (pname: self.lib.nameValuePair pname
              (nixpkgs.legacyPackages.${system}.vimUtils.buildVimPluginFrom2Nix {
                inherit pname;
                src = inputs.${pname};
                version = inputs.${pname}.shortRev;
              })) pnames);
        mkPackage = pkg: { ... }@args:
          nixpkgs.legacyPackages.${system}.callPackage pkg args;
      in
      mkVimPlugins [ "heirline-nvim" "filetype-nvim" "lsp_lines-nvim" ] // rec {
        firefox-custom = mkPackage ./pkgs/firefox { };
        gamescope = mkPackage ./pkgs/gamescope.nix { };
        rofi-wayland-unwrapped = mkPackage ./pkgs/rofi-wayland.nix { };
        rofi-wayland = with nixpkgs.legacyPackages.${system}; rofi.override {
          rofi-unwrapped = rofi-wayland-unwrapped;
        };
        wlr-spanbg = mkPackage ./pkgs/wlr-spanbg { };
      }
    );

    overlays = {
      vimPlugins = final: prev: {
        vimPlugins = prev.vimPlugins // {
          inherit (self.packages.${prev.system})
            heirline-nvim
            filetype-nvim
            lsp_lines-nvim;
        };
      };
      pkgs = final: prev: {
        inherit (self.packages.${prev.system})
          wlr-spanbg
          rofi-wayland-unwrapped
          rofi-wayland
          gamescope
          firefox-custom;
      };
    };

    nixosModules.home-manager.wayfire = import ./nixos/home-manager/wayfire;

    nixosConfigurations = with self.lib.extended; {
      # Desktop workstation
      mars = nixosSystem {
        system = "x86_64-linux";
        modules = [
          ({ config, lib, ... }: {
            nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
              "steam"
              "steam-run"
              "teamviewer"
              "teams"
            ];
          })
          ./hosts/mars/configuration.nix
          ./hosts/mars/hardware-configuration.nix
          ./nixos/encrypted-dns.nix
          ./nixos/steam
          ./nixos/teamviewer
          ./nixos/virtual-camera.nix
          nixos-hardware.nixosModules.common-cpu-intel
          nixos-hardware.nixosModules.common-pc-ssd
          # ./nixos/cross-aarch64.nix
        ] ++ forAllHomes [ "electro" ] [
          ./hosts/mars/displays.nix
          ./hosts/mars/home.nix
          ./modules/mpv.nix
          ./modules/neovim
          ./modules/nix-index.nix
          ./modules/themes/night
          ./modules/wayfire
        ];
        overlays = builtins.attrValues self.outputs.overlays ++ [
          # Use the git/master build
          (final: prev: {
            inherit (inputs.rnix-lsp.packages.${prev.system}) rnix-lsp;
          })
        ];
      };

      # Raspberry Pi 4B
      phobos = nixosSystem {
        system = "aarch64-linux";
        modules = [
          ./hosts/phobos/configuration.nix
          ./hosts/phobos/hardware-configuration.nix
          nixos-hardware.nixosModules.raspberry-pi-4
        ];
        overlays = builtins.attrValues self.outputs.overlays;
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
