{
  description = ''
    Personal NixOS system configurations, modules and packages
  '';

  inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-22.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-lib.url = "github:nix-community/nixpkgs.lib/master";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    hm-stable = {
      url = "github:nix-community/home-manager/release-22.05";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    hm-unstable = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs = {
        nixpkgs.follows = "nixpkgs-unstable";
        flake-utils.follows = "hm-unstable/utils";
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
    hm-stable,
    hm-unstable,
    nixos-wsl,
    sops-nix,
    impermanence,
  }:
  let
    inherit (nixpkgs-lib) lib;
    forAllSystems = lib.genAttrs [ "x86_64-linux" "aarch64-linux" ];
  in
  {
    legacyPackages = forAllSystems (system:
      lib.fix
        (lib.composeManyExtensions (builtins.attrValues self.overlays))
        nixpkgs-unstable.legacyPackages.${system});

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

    nixosConfigurations = let
      nixosWith = nixpkgs: home-manager:
        import ./modules/lib { inherit nixpkgs home-manager self; };
      nixosStable = nixosWith nixpkgs-stable hm-stable;
      nixosUnstable = nixosWith nixpkgs-unstable hm-unstable;
    in {
      terra = nixosUnstable {
        system = "x86_64-linux";

        manageSecrets.enable = true;
        manageState.enable = true;

        modules = {
          system = [
            ./hosts/kepler/wireguard.nix
            ./hosts/phobos/media-remote.nix
            ./hosts/terra/configuration.nix
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
            self.nixosModules.unfree
          ];
          users.electro = [
            ./hosts/terra/home.nix
            ./profiles/user/fish
            ./profiles/user/git
            ./profiles/user/gtk
            ./profiles/user/kitty
            ./profiles/user/lsd
            ./profiles/user/mpv
            ./profiles/user/neovim
            ./profiles/user/nix-index
            ./profiles/user/tealdeer
            ./profiles/user/wayfire
            ./profiles/user/zathura
          ];
        };
      };

      phobos = nixosStable {
        system = "aarch64-linux";

        manageSecrets.enable = true;
        manageState.enable = true;

        modules = {
          system = [
            ./hosts/kepler/wireguard.nix
            ./hosts/phobos/configuration.nix
            ./profiles/system/avahi
            ./profiles/system/common
            ./profiles/system/matrix
            ./profiles/system/ssh
            ./profiles/system/sudo
          ];
          users.pi = [
            ./hosts/phobos/home.nix
            ./profiles/user/fish
            ./profiles/user/git
          ];
        };
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

      jupiter = nixosUnstable {
        system = "x86_64-linux";

        manageSecrets.enable = true;

        modules = {
          system = [
            ./hosts/jupiter/configuration.nix
            ./hosts/kepler/wireguard.nix
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
            ./hosts/jupiter/home.nix
            ./profiles/user/fish
            ./profiles/user/git
            ./profiles/user/gtk
            ./profiles/user/kitty
            ./profiles/user/lsd
            ./profiles/user/neovim
            ./profiles/user/nix-index
            ./profiles/user/tealdeer
            ./profiles/user/wayfire
            ./profiles/user/zathura
          ];
        };
      };

      venus = nixosUnstable {
        system = "x86_64-linux";

        manageSecrets.enable = true;
        manageState.enable = true;

        modules = {
          system = [
            ./hosts/kepler/wireguard.nix
            ./hosts/venus/configuration.nix
            nixos-hardware.nixosModules.common-pc-laptop
            nixos-hardware.nixosModules.common-pc-laptop-ssd
            nixos-hardware.nixosModules.lenovo-thinkpad-x220
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
          users.electro = [
            ./hosts/venus/home.nix
            ./profiles/user/fish
            ./profiles/user/git
            ./profiles/user/gtk
            ./profiles/user/kitty
            ./profiles/user/lsd
            ./profiles/user/mpv
            ./profiles/user/neovim
            ./profiles/user/nix-index
            ./profiles/user/tealdeer
            ./profiles/user/wayfire
            ./profiles/user/zathura
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
            ./profiles/user/lsd
            ./profiles/user/neovim
            ./profiles/user/nix-index
            ./profiles/user/tealdeer
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
            ./profiles/user/lsd
            ./profiles/user/neovim
            ./profiles/user/nix-index
            ./profiles/user/tealdeer
          ];
        };
      };

      kepler = nixosStable {
        system = "x86_64-linux";

        manageSecrets.enable = true;

        modules.system = [
          ./hosts/kepler/configuration.nix
          ./hosts/kepler/wireguard.nix
          ./profiles/system/ssh
        ];
      };
    };
  };
}
