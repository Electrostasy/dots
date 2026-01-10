{ self, nixpkgs, ... }:

let
  inherit (nixpkgs) lib;

  inputModules = lib.pipe self.inputs [
    (lib.filterAttrs (_: lib.hasAttrByPath [ "nixosModules" "default" ]))
    (lib.mapAttrsToList (_: lib.getAttrFromPath [ "nixosModules" "default" ]))
  ];
in

lib.pipe ./. [
  builtins.readDir

  (lib.filterAttrs (name: _: name != "default.nix"))

  (lib.mapAttrs' (name: _:
    let
      hostName = lib.removeSuffix ".nix" name;
      defaultSopsFile = ./${name}/secrets.yaml;
    in
    {
      name = hostName;
      value = lib.nixosSystem {
        modules = inputModules ++ [
          self.outputs.nixosModules.default
          {
            # Allow modules to refer to this flake by argument.
            # WARN: Do not use `self` to import modules!
            _module.args.flake = self;

            sops.defaultSopsFile =
              lib.mkIf
                (builtins.pathExists defaultSopsFile)
                defaultSopsFile;

            networking = { inherit hostName; };
          }

          ../profiles/common.nix
          ./${name}
        ];
      };
    }))
]
