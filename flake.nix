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

  outputs = { self, nixpkgs, nixos-hardware, ... }: {
    legacyPackages =
      nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (system:
        nixpkgs.lib.fix
          (nixpkgs.lib.composeManyExtensions (builtins.attrValues self.overlays))
          nixpkgs.legacyPackages.${system});

    overlays = {
      default = import ./packages;
      customisations = final: prev: {
        libewf = prev.libewf.overrideAttrs (_: {
          # `ewfmount` depends on `fuse` to mount *.E01 forensic images.
          buildInputs = [ prev.fuse ];
        });

        fractal-next = prev.fractal-next.overrideAttrs (oldAttrs: {
          # Necessary to avoid 2hr+ builds, has to be built locally due to timeouts
          # on Hydra.
          nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ prev.git ];
          mesonFlags = (oldAttrs.mesonFlags or []) ++ [ "-Dprofile=hack" ];

          # For playing inline video: https://github.com/NixOS/nixpkgs/pull/261305
          buildInputs = oldAttrs.buildInputs ++ [ prev.gst_all_1.gst-plugins-good ];
        });
      };
    };

    homeManagerModules.wayfire = import ./modules/user/wayfire;

    nixosConfigurations = {
      terra = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit self; };
        modules = [
          ./hosts/kepler/wireguard-peer.nix
          ./hosts/terra/configuration.nix
          ./hosts/terra/home.nix
          ./profiles/system/common
          ./profiles/system/firefox
          ./profiles/system/graphical
          ./profiles/system/mullvad
          ./profiles/system/shell
          ./profiles/system/ssh
        ];
      };

      phobos = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit self; };
        modules = [
          ./hosts/kepler/wireguard-peer.nix
          ./hosts/phobos/configuration.nix
          ./profiles/system/common
          ./profiles/system/shell
          ./profiles/system/ssh
        ];
      };

      venus = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit self; };
        modules = [
          ./hosts/kepler/wireguard-peer.nix
          ./hosts/venus/configuration.nix
          ./hosts/venus/home.nix
          ./profiles/system/common
          ./profiles/system/firefox
          ./profiles/system/gnome
          ./profiles/system/mullvad
          ./profiles/system/shell
          ./profiles/system/ssh
          nixos-hardware.nixosModules.common-gpu-intel
          nixos-hardware.nixosModules.common-pc-laptop
          nixos-hardware.nixosModules.lenovo-thinkpad-x220
        ];
      };

      eris = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit self; };
        modules = [
          ./hosts/eris/configuration.nix
          ./hosts/eris/home.nix
          ./profiles/system/common
          ./profiles/system/shell
        ];
      };

      ceres = nixpkgs.lib.nixosSystem {
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

      kepler = nixpkgs.lib.nixosSystem {
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
