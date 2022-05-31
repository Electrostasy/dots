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
    sops-nix = {
      url = "github:Mic92/sops-nix/master";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-21_11.follows = "nixpkgs";
      };
    };
  };

  outputs = { self, nixpkgs, nixos-hardware, nixos-wsl, impermanence, sops-nix, ... }@inputs: {
    lib = import ./modules/lib { inherit self; };

    packages = self.lib.extended.forAllSystems (system:
      nixpkgs.legacyPackages.${system}.callPackage ./packages { flake = self; });

    overlays.default = final: prev:
      prev.lib.recursiveUpdate
        prev
        # TODO: callPackage/self.packages just gives infinite recursion errors if used here
        (import ./packages { inherit (prev) lib; pkgs = nixpkgs.legacyPackages.${prev.system}; flake = self; });

    nixosModules = {
      home-manager.wayfire = import ./modules/user/wayfire;
      unfree = import ./modules/system/unfree;
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
          ./profiles/system/audio
          ./profiles/system/avahi
          ./profiles/system/common
          ./profiles/system/dconf
          ./profiles/system/dnscrypt-proxy2
          ./profiles/system/flatpak
          ./profiles/system/graphical
          ./profiles/system/login-manager
          ./profiles/system/ssh
          ./profiles/system/steam
          ./profiles/system/sudo
          ./profiles/system/v4l2loopback
          self.nixosModules.unfree
          sops-nix.nixosModules.sops
        ] ++ forAllHomes [ "electro" ] [
          ./hosts/mars/home.nix
          ./profiles/user/fish
          ./profiles/user/kitty
          ./profiles/user/mpv
          ./profiles/user/neovim
          ./profiles/user/nix-index
          ./profiles/user/wayfire
        ];
        overlays = [ self.overlays.default ];
      };

      phobos = nixosSystem {
        system = "aarch64-linux";
        modules = [
          ./hosts/phobos/configuration.nix
          impermanence.nixosModules.impermanence
          nixos-hardware.nixosModules.raspberry-pi-4
          ./profiles/system/common
          ./profiles/system/matrix
          sops-nix.nixosModules.sops
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
          ./profiles/system/audio
          ./profiles/system/avahi
          ./profiles/system/common
          ./profiles/system/dconf
          ./profiles/system/dnscrypt-proxy2
          ./profiles/system/graphical
          ./profiles/system/login-manager
          ./profiles/system/ssh
          ./profiles/system/sudo
          sops-nix.nixosModules.sops
        ] ++ forAllHomes [ "gediminas" ] [
          ./hosts/mercury/home.nix
          ./profiles/user/fish
          ./profiles/user/kitty
          ./profiles/user/neovim
          ./profiles/user/nix-index
          ./profiles/user/wayfire
        ];
        overlays = [ self.overlays.default ];
      };

      BERLA = nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/BERLA/configuration.nix
          nixos-wsl.nixosModules.wsl
          ./profiles/system/common
        ] ++ forAllHomes [ "nixos" ] [
          ./hosts/BERLA/home.nix
          ./profiles/user/fish
          ./profiles/user/neovim
          ./profiles/user/nix-index
        ];
        overlays = [ self.overlays.default ];
      };
    };
  };
}
