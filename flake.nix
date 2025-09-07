{
  description = ''
    Personal NixOS system configurations, modules and packages
  '';

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    preservation.url = "github:nix-community/preservation/main";

    sops-nix = {
      url = "github:Mic92/sops-nix/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: {
    checks = import ./checks/all-checks.nix inputs;
    legacyPackages = import ./pkgs/all-packages.nix inputs;
    nixosConfigurations = import ./hosts/all-hosts.nix inputs;
    nixosModules = import ./modules/all-modules.nix inputs;
    overlays = import ./overlays/all-overlays.nix inputs;
  };
}
