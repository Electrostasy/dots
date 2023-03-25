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
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "home-manager/utils";
      };
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

  outputs = {
    self,
    nixpkgs,
    nixos-hardware,
    home-manager,
    nixos-wsl,
    sops-nix,
    impermanence,
  }:
  let
    inherit (nixpkgs) lib;
  in
  {
    legacyPackages =
      lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (system:
        lib.fix
          (lib.composeManyExtensions (builtins.attrValues self.overlays))
          nixpkgs.legacyPackages.${system});

    overlays = {
      additions = import ./packages;

      customisations = final: prev: {
        libewf = prev.libewf.overrideAttrs (_: {
          # `ewfmount` depends on `fuse` to mount *.E01 forensic images
          buildInputs = [ prev.fuse ];
        });

        libreoffice = prev.libreoffice.overrideAttrs (_: {
          langs = [ "en-US" "lt" ];
        });
      };
    };

    homeManagerModules = {
      fuzzel = import ./modules/user/fuzzel;
      wayfire = import ./modules/user/wayfire;
    };

    nixosConfigurations = {
      terra = lib.nixosSystem {
        specialArgs = { inherit self; };

        modules = [
          home-manager.nixosModules.default
          impermanence.nixosModule
          sops-nix.nixosModules.default
          ./profiles/system/common

          # Make host accessible via Wireguard VPN.
          ./hosts/kepler/wireguard-peer.nix

          # Host system and home configurations.
          ./hosts/terra/configuration.nix
          ./hosts/terra/home.nix

          # Shared profiles.
          ./profiles/system/audio
          ./profiles/system/git-headed
          ./profiles/system/graphical
          ./profiles/system/mullvad
          ./profiles/system/ssh
          ./profiles/system/sudo
        ];
      };

      phobos = lib.nixosSystem {
        specialArgs = { inherit self; };

        modules = [
          home-manager.nixosModules.default
          impermanence.nixosModule
          sops-nix.nixosModules.default
          ./profiles/system/common

          # Make host accessible via Wireguard VPN.
          ./hosts/kepler/wireguard-peer.nix

          # Host system and home configurations.
          ./hosts/phobos/configuration.nix
          ./hosts/phobos/home.nix

          # Shared profiles.
          ./profiles/system/git-headless
          ./profiles/system/ssh
          ./profiles/system/sudo
        ];
      };

      deimos = lib.nixosSystem {
        specialArgs = { inherit self; };

        modules = [
          home-manager.nixosModules.default
          impermanence.nixosModule
          sops-nix.nixosModules.default
          ./profiles/system/common

          # Host system and home configurations.
          ./hosts/deimos/configuration.nix
          ./hosts/deimos/home.nix

          # Shared profiles.
          ./profiles/system/git-headless
          ./profiles/system/ssh
          ./profiles/system/sudo
        ];
      };

      jupiter = lib.nixosSystem {
        specialArgs = { inherit self; };

        modules = [
          nixos-hardware.nixosModules.common-gpu-intel
          nixos-hardware.nixosModules.common-pc-laptop
          nixos-hardware.nixosModules.common-pc-laptop-ssd
          nixos-hardware.nixosModules.lenovo-thinkpad-t420

          home-manager.nixosModules.default
          sops-nix.nixosModules.default
          ./profiles/system/common

          # Make host accessible via Wireguard VPN.
          ./hosts/kepler/wireguard-peer.nix

          # Host system and home configurations.
          ./hosts/jupiter/configuration.nix
          ./hosts/jupiter/home.nix

          # Shared profiles.
          ./profiles/system/audio
          ./profiles/system/git-headed
          ./profiles/system/graphical
          ./profiles/system/mullvad
          ./profiles/system/ssh
          ./profiles/system/sudo
        ];
      };

      venus = lib.nixosSystem {
        specialArgs = { inherit self; };

        modules = [
          nixos-hardware.nixosModules.common-gpu-intel
          nixos-hardware.nixosModules.common-pc-laptop
          nixos-hardware.nixosModules.lenovo-thinkpad-x220

          home-manager.nixosModules.default
          impermanence.nixosModule
          sops-nix.nixosModules.default
          ./profiles/system/common

          # Make host accessible via Wireguard VPN.
          ./hosts/kepler/wireguard-peer.nix

          # Host system and home configurations.
          ./hosts/venus/configuration.nix
          ./hosts/venus/home.nix

          # Shared profiles.
          ./profiles/system/audio
          ./profiles/system/git-headed
          ./profiles/system/graphical
          ./profiles/system/mullvad
          ./profiles/system/ssh
          ./profiles/system/sudo
        ];
      };

      eris = lib.nixosSystem {
        specialArgs = { inherit self; };

        modules = [
          home-manager.nixosModules.default
          nixos-wsl.nixosModules.wsl
          ./profiles/system/common

          # Host system and home configurations.
          ./hosts/eris/configuration.nix
          ./hosts/eris/home.nix

          # Shared profiles.
          ./profiles/system/git-headless
        ];
      };

      ceres = lib.nixosSystem {
        specialArgs = { inherit self; };

        modules = [
          nixos-hardware.nixosModules.common-cpu-intel

          home-manager.nixosModules.default
          impermanence.nixosModule
          sops-nix.nixosModules.default
          ./profiles/system/common

          # Host system and home configurations.
          ./hosts/ceres/configuration.nix
          ./hosts/ceres/home.nix

          # Shared profiles.
          ./profiles/system/git-headless
          ./profiles/system/graphical
          ./profiles/system/ssh
          ./profiles/system/sudo
        ];
      };

      kepler = lib.nixosSystem {
        specialArgs = { inherit self; };

        modules = [
          sops-nix.nixosModules.default
          ./profiles/system/common

          # Make host accessible via Wireguard VPN (server).
          ./hosts/kepler/wireguard-server.nix

          # Host system configuration.
          ./hosts/kepler/configuration.nix

          # Shared profiles.
          ./profiles/system/git-headless
          ./profiles/system/ssh
        ];
      };
    };
  };
}
