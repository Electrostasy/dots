{
  description = ''
    Personal NixOS system configurations, modules and packages
  '';

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";

    preservation.url = "github:nix-community/preservation/main";

    sops-nix = {
      url = "github:Mic92/sops-nix/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: {
    checks = import ./checks inputs;
    legacyPackages = import ./pkgs inputs;
    nixosConfigurations = import ./hosts inputs;
    nixosModules = import ./modules inputs;
    overlays = import ./overlays inputs;
  };
}
