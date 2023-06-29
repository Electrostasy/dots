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

  outputs = {
    self,
    nixpkgs,
    nixos-hardware,
    ...
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
          # `ewfmount` depends on `fuse` to mount *.E01 forensic images.
          buildInputs = [ prev.fuse ];
        });
      };
    };

    homeManagerModules = {
      wayfire = import ./modules/user/wayfire;
    };

    nixosConfigurations = {
      terra = lib.nixosSystem {
        specialArgs = { inherit self; };

        modules = [
          ./hosts/kepler/wireguard-peer.nix
          ./hosts/terra/configuration.nix
          ./hosts/terra/home.nix
          ./profiles/system/audio
          ./profiles/system/common
          ./profiles/system/firefox
          ./profiles/system/graphical
          ./profiles/system/mullvad
          ./profiles/system/shell
          ./profiles/system/ssh
        ];
      };

      phobos = lib.nixosSystem {
        specialArgs = { inherit self; };

        modules = [
          ./hosts/kepler/wireguard-peer.nix
          ./hosts/phobos/configuration.nix
          ./profiles/system/common
          ./profiles/system/shell
          ./profiles/system/ssh
        ];
      };

      deimos = lib.nixosSystem {
        specialArgs = { inherit self; };

        modules = [
          ./hosts/deimos/configuration.nix
          ./profiles/system/common
          ./profiles/system/shell
          ./profiles/system/ssh
        ];
      };

      jupiter = lib.nixosSystem {
        specialArgs = { inherit self; };

        modules = [
          ./hosts/jupiter/configuration.nix
          ./hosts/jupiter/home.nix
          ./hosts/kepler/wireguard-peer.nix
          ./profiles/system/audio
          ./profiles/system/common
          ./profiles/system/firefox
          ./profiles/system/graphical
          ./profiles/system/mullvad
          ./profiles/system/shell
          ./profiles/system/ssh
          nixos-hardware.nixosModules.common-gpu-intel
          nixos-hardware.nixosModules.common-pc-laptop
          nixos-hardware.nixosModules.common-pc-laptop-ssd
          nixos-hardware.nixosModules.lenovo-thinkpad-t420
        ];
      };

      venus = lib.nixosSystem {
        specialArgs = { inherit self; };

        modules = [
          ./hosts/kepler/wireguard-peer.nix
          ./hosts/venus/configuration.nix
          ./hosts/venus/home.nix
          ./profiles/system/audio
          ./profiles/system/common
          ./profiles/system/firefox
          ./profiles/system/mullvad
          ./profiles/system/shell
          ./profiles/system/ssh
          nixos-hardware.nixosModules.common-gpu-intel
          nixos-hardware.nixosModules.common-pc-laptop
          nixos-hardware.nixosModules.lenovo-thinkpad-x220
        ];
      };

      eris = lib.nixosSystem {
        specialArgs = { inherit self; };

        modules = [
          ./hosts/eris/configuration.nix
          ./hosts/eris/home.nix
          ./profiles/system/common
          ./profiles/system/shell
        ];
      };

      ceres = lib.nixosSystem {
        specialArgs = { inherit self; };

        modules = [
          ./hosts/ceres/configuration.nix
          ./hosts/ceres/home.nix
          ./profiles/system/common
          ./profiles/system/firefox
          ./profiles/system/graphical
          ./profiles/system/shell
          ./profiles/system/ssh
          nixos-hardware.nixosModules.common-cpu-intel
        ];
      };

      kepler = lib.nixosSystem {
        specialArgs = { inherit self; };

        modules = [
          ./hosts/kepler/configuration.nix
          ./hosts/kepler/wireguard-server.nix
          ./profiles/system/common
          ./profiles/system/shell
          ./profiles/system/ssh
        ];
      };
    };
  };
}
