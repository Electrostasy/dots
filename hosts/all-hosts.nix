{ self, nixpkgs, ... }:

let
  inherit (nixpkgs) lib;
in

# Combines the expressions from all the files in this directory containing
# NixOS configurations.

lib.pipe ./. [
  builtins.readDir

  (lib.filterAttrs (name: _: name != "all-hosts.nix"))

  (lib.mapAttrs' (name: _:
    let
      hostName = lib.removeSuffix ".nix" name;

      inputModules = lib.pipe self.inputs [
        (lib.filterAttrs (_: lib.hasAttrByPath [ "nixosModules" "default" ]))
        (lib.mapAttrsToList (_: lib.getAttrFromPath [ "nixosModules" "default" ]))
      ];
      outputModules = lib.attrValues self.nixosModules;
    in
    {
      name = hostName;
      value = lib.nixosSystem {
        modules = lib.concatLists [
          inputModules
          outputModules
          [
            # Allow modules to refer to this flake by argument.
            # WARN: Do not use `self` to import modules!
            { _module.args.flake = self; }

            ../profiles/common.nix
            { networking = { inherit hostName; }; }
            ./${name}
          ]
        ];
      };
    }))
]
