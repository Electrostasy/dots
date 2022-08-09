{ nixpkgs, home-manager, self }:

{
  system,
  modules,
  ...
} @ args:

let
  inherit (nixpkgs) lib;
  pkgs = nixpkgs.legacyPackages.${system};

  keyFile = args.manageSecrets.keyFile or "/var/lib/sops-nix/keys.txt";
  stateDir = if args.manageState.enable or false
    # If state is managed, use the (default) state directory
    then (args.manageState.default or "/state")
    # Otherwise, use an empty string (i.e. none when interpolated in paths)
    else "";

  systemModules = lib.singleton {
    environment.defaultPackages = lib.mkForce [];
    nixpkgs = {
      hostPlatform = lib.mkDefault system;
      overlays = builtins.attrValues self.overlays;
    };
    nix = {
      package = pkgs.nixFlakes;
      extraOptions = "experimental-features = nix-command flakes";

      # Setting $NIX_PATH to Flake-provided nixpkgs allows repl and other
      # channel-dependent programs to use the correct nixpkgs
      settings.nix-path = [ "nixpkgs=${nixpkgs}" ];
      registry.nixpkgs = {
        from = { type = "indirect"; id = "nixpkgs"; };
        flake = nixpkgs;
      };
    };
  } ++ modules.system;

  userModules = builtins.map
    (user: { home-manager.users.${user}.imports = modules.users.${user}; })
    (builtins.attrNames modules.users or {});
  
  homeManagerConfig = {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      sharedModules = builtins.attrValues self.nixosModules.home-manager;
    };
  };

  sopsConfig = let
    keyFileDirectory =
      lib.concatStringsSep "/"
        (lib.init (lib.splitString "/" keyFile));
  in lib.mkIf (args.manageSecrets.enable or false) {
    fileSystems.${keyFileDirectory} = lib.mkIf (args.manageState.enable or false) {
      device = lib.concatStrings [ stateDir keyFileDirectory ];
      fsType = "none";
      options = [ "bind" ];
      depends = [ stateDir ];
      neededForBoot = true;
    };

    environment = {
      sessionVariables.SOPS_AGE_KEY_FILE = keyFile;
      systemPackages = with pkgs; [ sops rage ];
    };

    sops = {
      age = {
        inherit keyFile;
        sshKeyPaths = [];
      };
      gnupg.sshKeyPaths = [];
    };
  };
in
nixpkgs.lib.nixosSystem {
  inherit system;
  modules =
    systemModules
    ++ lib.optionals (userModules != []) ([ home-manager.nixosModule homeManagerConfig ] ++ userModules)
    ++ lib.optionals (args.manageSecrets.enable or false) [ self.inputs.sops-nix.nixosModule sopsConfig ]
    ++ lib.optional (args.manageState.enable or false) self.inputs.impermanence.nixosModule;
  specialArgs = {
    persistMount = stateDir;
    inherit lib self;
  };
}
