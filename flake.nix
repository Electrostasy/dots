{
  description = ''
    Personal NixOS system configurations, modules and packages
  '';

  inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-22.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-lib.url = "github:nix-community/nixpkgs.lib/master";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        flake-utils.follows = "home-manager/utils";
      };
    };
    sops-nix = {
      url = "github:Mic92/sops-nix/master";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        nixpkgs-22_05.follows = "nixpkgs-stable";
      };
    };
    impermanence.url = "github:nix-community/impermanence/master";
  };

  outputs = {
    self,
    nixpkgs-stable,
    nixpkgs-unstable,
    nixpkgs-lib,
    nixos-hardware,
    home-manager,
    nixos-wsl,
    sops-nix,
    impermanence,
  }:
  let
    inherit (nixpkgs-lib) lib;
    supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
    forSystems = systems: f:
      lib.genAttrs systems (system:
        f system nixpkgs-unstable.legacyPackages.${system});
    forAllSystems = forSystems supportedSystems;
  in
  {
    legacyPackages = forAllSystems (system: pkgs: pkgs.callPackage ./packages { });

    overlays.default = final: prev:
      # TODO: There has to be a better way to generate overlays from packages
      prev.lib.recursiveUpdate
        prev
        (import ./packages { inherit (prev) lib; pkgs = nixpkgs-unstable.legacyPackages.${prev.system}; });

    nixosModules = {
      home-manager.wayfire = import ./modules/user/wayfire;
      unfree = import ./modules/system/unfree;
    };

    nixosConfigurations = let
      nixosWith = nixpkgs: import ./modules/lib { inherit nixpkgs self; };
      nixosStable = nixosWith nixpkgs-stable;
      nixosUnstable = nixosWith nixpkgs-unstable;
    in {
      mars = nixosUnstable {
        system = "x86_64-linux";

        manageSecrets.enable = true;
        manageState.enable = true;

        modules = {
          system = [
            ./hosts/mars/configuration.nix
            ./hosts/phobos/media-remote.nix
            nixos-hardware.nixosModules.common-cpu-intel
            nixos-hardware.nixosModules.common-pc-ssd
            ./profiles/system/audio
            ./profiles/system/avahi
            ./profiles/system/common
            ./profiles/system/dconf
            ./profiles/system/dnscrypt-proxy2
            ./profiles/system/graphical
            ./profiles/system/login-manager
            ./profiles/system/ssh
            ./profiles/system/sudo
            ./profiles/system/v4l2loopback
            self.nixosModules.unfree
          ];
          users.electro = [
            ./hosts/mars/home.nix
            ./profiles/user/fish
            ./profiles/user/git
            ./profiles/user/gtk
            ./profiles/user/kitty
            ./profiles/user/mpv
            ./profiles/user/neovim
            ./profiles/user/nix-index
            ./profiles/user/wayfire
          ];
        };
      };

      phobos = nixosStable {
        system = "aarch64-linux";

        manageSecrets.enable = true;
        manageState.enable = true;

        modules.system = [
          ./hosts/phobos/configuration.nix
          nixos-hardware.nixosModules.raspberry-pi-4
          ./profiles/system/avahi
          ./profiles/system/common
          ./profiles/system/matrix
          ./profiles/system/ssh
          ./profiles/system/sudo
        ];
      };

      deimos = nixosStable {
        system = "aarch64-linux";

        manageSecrets.enable = true;
        manageState.enable = true;

        modules = {
          system = [
            ./hosts/deimos/configuration.nix
            ./profiles/system/avahi
            ./profiles/system/common
            ./profiles/system/ssh
            ./profiles/system/sudo
          ];
          users.pi = [
            ./hosts/deimos/home.nix
            ./profiles/user/fish
            ./profiles/user/git
          ];
        };
      };

      mercury = nixosUnstable {
        system = "x86_64-linux";

        manageSecrets.enable = true;

        modules = {
          system = [
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
          ];
          users.gediminas = [
            ./hosts/mercury/home.nix
            ./profiles/user/fish
            ./profiles/user/git
            ./profiles/user/gtk
            ./profiles/user/kitty
            ./profiles/user/neovim
            ./profiles/user/nix-index
            ./profiles/user/wayfire
          ];
        };
      };

      eris = nixosUnstable {
        system = "x86_64-linux";

        modules = {
          system = [
            ./hosts/eris/configuration.nix
            nixos-wsl.nixosModules.wsl
            ./profiles/system/common
          ];
          users.nixos = [
            ./hosts/eris/home.nix
            ./profiles/user/fish
            ./profiles/user/git
            ./profiles/user/neovim
            ./profiles/user/nix-index
          ];
        };
      };

      ceres = nixosUnstable {
        system = "x86_64-linux";

        manageSecrets.enable = true;
        manageState.enable = true;

        modules = {
          system = [
            ./hosts/ceres/configuration.nix
            nixos-hardware.nixosModules.common-cpu-intel
            ./profiles/system/common
            ./profiles/system/graphical
            ./profiles/system/ssh
            ./profiles/system/sudo
          ];
          users.gediminas = [
            ./hosts/ceres/home.nix
            ./profiles/user/fish
            ./profiles/user/git
            ./profiles/user/neovim
            ./profiles/user/nix-index
          ];
        };
      };
    };
  };
}
