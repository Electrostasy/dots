{ self, nixpkgs, ... }:

let
  inherit (nixpkgs) lib;
in

lib.pipe ./. [
  builtins.readDir

  (lib.flip removeAttrs [(baseNameOf __curPos.file)])

  builtins.attrNames

  (lib.flip lib.genAttrs (host: lib.nixosSystem {
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
  }))
]
