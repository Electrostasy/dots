{
  description = ''
    NixOS systems, (home-manager) modules, packages and overlays I use
  '';

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence = {
      url = "github:nix-community/impermanence/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fzf-lua = {
      url = "github:ibhagwan/fzf-lua";
      flake = false;
    };
    heirline-nvim = {
      url = "github:rebelot/heirline.nvim";
      flake = false;
    };
    hlargs-nvim = {
      url = "github:m-demare/hlargs.nvim";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, impermanence, nixos-hardware, nixos-wsl, ... }@inputs: {
    lib = import ./nixos/lib { inherit (nixpkgs) lib; inherit self; };

    packages = self.lib.extended.forAllSystems (system:
      let
        mkVimPlugin = pname:
          nixpkgs.legacyPackages.${system}.vimUtils.buildVimPluginFrom2Nix {
            inherit pname;
            src = inputs.${pname};
            version = let
              date = inputs.${pname}.lastModifiedDate;
              year = builtins.substring 0 4 date;
              month = builtins.substring 4 2 date;
              day = builtins.substring 6 2 date;
            in "unstable-${year}-${month}-${day}";
          };
        mkVimPlugins = pnames:
          with self.lib;
          foldl recursiveUpdate { }
          (builtins.map (pname: { ${pname} = mkVimPlugin pname; }) pnames);
        inherit (nixpkgs.legacyPackages.${system}) callPackage;
      in mkVimPlugins [ "fzf-lua" "heirline-nvim" "hlargs-nvim" ] // rec {
        eww-wayland = callPackage ./pkgs/eww.nix { };
        firefox-custom = callPackage ./pkgs/firefox { };
        gamescope = callPackage ./pkgs/gamescope.nix { };
        nerdfonts-patch = callPackage ./pkgs/nerdfonts-patch.nix { };
        wlr-spanbg = callPackage ./pkgs/wlr-spanbg { };
        simp1e-cursor-theme = callPackage ./pkgs/simp1e-cursor-theme.nix { };
        wlopm = callPackage ./pkgs/wlopm.nix { };
        wayfire-git = callPackage ./pkgs/wayfire/wayfire-git.nix { };
        wayfire-firedecor = callPackage ./pkgs/wayfire/firedecor.nix { wayfire = wayfire-git; };
      });

    overlays = {
      vimPlugins = final: prev: {
        vimPlugins = prev.vimPlugins // {
          inherit (self.packages.${prev.system})
            filetype-nvim heirline-nvim hlargs-nvim;
        };
      };
      pkgs = final: prev: {
        inherit (self.packages.${prev.system})
          eww-wayland firefox-custom gamescope nerdfonts-patch wlr-spanbg simp1e-cursor-theme wlopm wayfire-git;
        wayfirePlugins.firedecor = self.packages.${prev.system}.wayfire-firedecor;
      };
    };

    nixosModules = {
      home-manager.wayfire = import ./nixos/modules/home-manager/wayfire;
      unfree = import ./nixos/modules/unfree.nix;
    };

    nixosConfigurations = with self.lib.extended; {
      mars = nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/mars/configuration.nix
          ./hosts/phobos/nfs-client.nix
          impermanence.nixosModules.impermanence
          nixos-hardware.nixosModules.common-cpu-intel
          nixos-hardware.nixosModules.common-pc-ssd
          ./nixos/modules/profiles/audio
          ./nixos/modules/profiles/avahi
          ./nixos/modules/profiles/dconf
          ./nixos/modules/profiles/dnscrypt-proxy2
          ./nixos/modules/profiles/flatpak
          ./nixos/modules/profiles/graphical
          ./nixos/modules/profiles/login-manager
          ./nixos/modules/profiles/ssh
          ./nixos/modules/profiles/sudo
          ./nixos/modules/profiles/v4l2loopback
          self.nixosModules.unfree
        ] ++ forAllHomes [ "electro" ] [
          ./hosts/mars/displays.nix
          ./hosts/mars/home.nix
          ./modules/fish.nix
          ./modules/kitty.nix
          ./modules/mpv.nix
          ./modules/neovim
          ./modules/nix-index.nix
          ./modules/wayfire
        ];
        overlays = builtins.attrValues self.overlays;
      };

      phobos = nixosSystem {
        system = "aarch64-linux";
        modules = [
          ./hosts/phobos/configuration.nix
          impermanence.nixosModules.impermanence
          nixos-hardware.nixosModules.raspberry-pi-4
          ./nixos/modules/profiles/matrix
        ];
      };

      deimos = nixosSystem {
        system = "aarch64-linux";
        modules = [ ./hosts/deimos/configuration.nix ];
      };

      mercury = nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/mercury/configuration.nix
          nixos-hardware.nixosModules.common-pc-laptop
          nixos-hardware.nixosModules.common-pc-laptop-ssd
          nixos-hardware.nixosModules.lenovo-thinkpad-t420
          ./nixos/modules/profiles/audio
          ./nixos/modules/profiles/avahi
          ./nixos/modules/profiles/dconf
          ./nixos/modules/profiles/dnscrypt-proxy2
          ./nixos/modules/profiles/graphical
          ./nixos/modules/profiles/login-manager
          ./nixos/modules/profiles/ssh
          ./nixos/modules/profiles/sudo
        ] ++ forAllHomes [ "gediminas" ] [
          ./hosts/mercury/home.nix
          ./modules/fish.nix
          ./modules/kitty.nix
          ./modules/neovim
          ./modules/nix-index.nix
          ./modules/wayfire
        ];
        overlays = builtins.attrValues self.overlays;
      };

      BERLA = nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/BERLA/configuration.nix
          nixos-wsl.nixosModules.wsl
        ] ++ forAllHomes [ "nixos" ] [
          ./hosts/BERLA/home.nix
          ./modules/fish.nix
          ./modules/neovim
          ./modules/nix-index.nix
        ];
        overlays = builtins.attrValues self.overlays;
      };
    };
  };
}
