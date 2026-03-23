{ self, nixpkgs, ... }:

let
  inherit (nixpkgs) lib;

  hosts = lib.pipe ./. [
    builtins.readDir
    (lib.filterAttrs (name: _: name != "default.nix"))
    lib.attrNames
  ];
in
  lib.genAttrs hosts (host:
    lib.nixosSystem {
      modules = [
        self.inputs.preservation.nixosModules.default
        self.inputs.sops-nix.nixosModules.default
        self.outputs.nixosModules.default
        {
          _module.args.flake = self;

          sops.defaultSopsFile = ./${host}/secrets.yaml;

          networking.hostName = lib.removeSuffix ".nix" host;
        }
        ../profiles/common.nix
        ./${host}
      ];
    }
  )
