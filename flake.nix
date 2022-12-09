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

    nixosModules = {
      unfree = import ./modules/system/unfree;
    };

    homeManagerModules = {
      wayfire = import ./modules/user/wayfire;
    };

    nixosConfigurations = {
      terra = lib.nixosSystem {
        specialArgs = { inherit self; };

        modules = [{
          imports = [
            nixos-hardware.nixosModules.common-cpu-intel
            nixos-hardware.nixosModules.common-gpu-amd
            nixos-hardware.nixosModules.common-pc-ssd

            home-manager.nixosModule
            impermanence.nixosModule
            sops-nix.nixosModule
            ./profiles/system/common

            ./hosts/kepler/wireguard.nix
            ./hosts/phobos/media-remote.nix
            ./hosts/terra/configuration.nix
            ./profiles/system/audio
            ./profiles/system/avahi
            ./profiles/system/dnscrypt-proxy2
            ./profiles/system/git-headed
            ./profiles/system/graphical
            ./profiles/system/mullvad
            ./profiles/system/ssh
            ./profiles/system/sudo
          ];

          home-manager.users.electro.imports = [
            ./hosts/terra/home.nix
            ./profiles/user/fish
            ./profiles/user/kitty
            ./profiles/user/lsd
            ./profiles/user/mpv
            ./profiles/user/neovim
            ./profiles/user/tealdeer
            ./profiles/user/wayfire
            ./profiles/user/zathura
          ];
        }];
      };

      phobos = lib.nixosSystem {
        specialArgs = { inherit self; };

        modules = [{
          imports = [
            home-manager.nixosModule
            impermanence.nixosModule
            sops-nix.nixosModule
            ./profiles/system/common

            ./hosts/kepler/wireguard.nix
            ./hosts/phobos/configuration.nix
            ./profiles/system/avahi
            ./profiles/system/git-headless
            ./profiles/system/matrix
            ./profiles/system/ssh
            ./profiles/system/sudo
          ];

          home-manager.users.pi.imports = [
            ./hosts/phobos/home.nix
            ./profiles/user/fish
          ];
        }];
      };

      deimos = lib.nixosSystem {
        specialArgs = { inherit self; };

        modules = [{
          imports = [
            home-manager.nixosModule
            impermanence.nixosModule
            sops-nix.nixosModule
            ./profiles/system/common

            ./hosts/deimos/configuration.nix
            ./profiles/system/avahi
            ./profiles/system/git-headless
            ./profiles/system/ssh
            ./profiles/system/sudo
          ];

          home-manager.users.pi.imports = [
            ./hosts/deimos/home.nix
            ./profiles/user/fish
          ];
        }];
      };

      jupiter = lib.nixosSystem {
        specialArgs = { inherit self; };

        modules = [{
          imports = [
            nixos-hardware.nixosModules.common-gpu-intel
            nixos-hardware.nixosModules.common-pc-laptop
            nixos-hardware.nixosModules.common-pc-laptop-ssd
            nixos-hardware.nixosModules.lenovo-thinkpad-t420

            home-manager.nixosModule
            sops-nix.nixosModule
            ./profiles/system/common

            ./hosts/jupiter/configuration.nix
            ./hosts/kepler/wireguard.nix
            ./profiles/system/audio
            ./profiles/system/avahi
            ./profiles/system/dnscrypt-proxy2
            ./profiles/system/git-headed
            ./profiles/system/graphical
            ./profiles/system/mullvad
            ./profiles/system/ssh
            ./profiles/system/sudo
          ];

          home-manager.users.gediminas.imports = [
            ./hosts/jupiter/home.nix
            ./profiles/user/fish
            ./profiles/user/kitty
            ./profiles/user/lsd
            ./profiles/user/neovim
            ./profiles/user/tealdeer
            ./profiles/user/wayfire
            ./profiles/user/zathura
          ];
        }];
      };

      venus = lib.nixosSystem {
        specialArgs = { inherit self; };

        modules = [{
          imports = [
            nixos-hardware.nixosModules.common-gpu-intel
            nixos-hardware.nixosModules.common-pc-laptop
            nixos-hardware.nixosModules.common-pc-laptop-ssd
            nixos-hardware.nixosModules.lenovo-thinkpad-x220

            home-manager.nixosModule
            impermanence.nixosModule
            sops-nix.nixosModule
            ./profiles/system/common

            ./hosts/kepler/wireguard.nix
            ./hosts/venus/configuration.nix
            ./profiles/system/audio
            ./profiles/system/avahi
            ./profiles/system/dnscrypt-proxy2
            ./profiles/system/git-headed
            ./profiles/system/graphical
            ./profiles/system/mullvad
            ./profiles/system/ssh
            ./profiles/system/sudo
          ];

          home-manager.users.electro.imports = [
            ./hosts/venus/home.nix
            ./profiles/user/fish
            ./profiles/user/kitty
            ./profiles/user/lsd
            ./profiles/user/mpv
            ./profiles/user/neovim
            ./profiles/user/tealdeer
            ./profiles/user/wayfire
            ./profiles/user/zathura
          ];
        }];
      };

      eris = lib.nixosSystem {
        specialArgs = { inherit self; };

        modules = [{
          imports = [
            home-manager.nixosModule
            nixos-wsl.nixosModules.wsl
            ./profiles/system/common

            ./hosts/eris/configuration.nix
            ./profiles/system/git-headless
          ];

          home-manager.users.nixos.imports = [
            ./hosts/eris/home.nix
            ./profiles/user/fish
            ./profiles/user/lsd
            ./profiles/user/neovim
            ./profiles/user/tealdeer
          ];
        }];
      };

      ceres = lib.nixosSystem {
        specialArgs = { inherit self; };

        modules = [{
          imports = [
            nixos-hardware.nixosModules.common-cpu-intel

            home-manager.nixosModule
            impermanence.nixosModule
            sops-nix.nixosModule
            ./profiles/system/common

            ./hosts/ceres/configuration.nix
            ./profiles/system/git-headless
            ./profiles/system/graphical
            ./profiles/system/ssh
            ./profiles/system/sudo
          ];

          home-manager.users.gediminas.imports = [
            ./hosts/ceres/home.nix
            ./profiles/user/fish
            ./profiles/user/lsd
            ./profiles/user/neovim
            ./profiles/user/tealdeer
          ];
        }];
      };

      kepler = lib.nixosSystem {
        specialArgs = { inherit self; };

        modules = [
          sops-nix.nixosModule
          ./profiles/system/common

          ./hosts/kepler/configuration.nix
          ./hosts/kepler/wireguard.nix
          ./profiles/system/git-headless
          ./profiles/system/ssh
        ];
      };
    };
  };
}
