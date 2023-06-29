{ config, pkgs, lib, self, ... }:

{
  imports = [
    self.inputs.nixos-wsl.nixosModules.wsl
    ./home-manager.nix
    ./sops.nix
    ./impermanence.nix
  ];

  i18n = {
    defaultLocale = "en_US.UTF-8";

    # Necessary to support different encodings of e.g. file names. Without
    # ja_JP, Japanese symbols in filenames will not be displayed correctly.
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "ja_JP.UTF-8/UTF-8"
      "lt_LT.UTF-8/UTF-8"

      # Needed for LC_TIME.
      "en_DK.UTF-8/UTF-8"
    ];

    extraLocaleSettings = {
      # en_DK follows the ISO-8601 standard and time is formatted sanely.
      LC_TIME = "en_DK.UTF-8";
    };
  };

  time.timeZone = lib.mkDefault "Europe/Vilnius";

  nixpkgs = {
    overlays = builtins.attrValues self.overlays;
    config.allowAliases = false;
  };

  environment.defaultPackages = with pkgs; lib.mkForce [
    file
    ouch
    parted
  ];

  programs.git = {
    enable = true;

    config = {
      # https://github.com/NixOS/nixpkgs/issues/169193#issuecomment-1103816735
      safe.directory = "/etc/nixos";

      url = {
        "https://github.com/".insteadOf = [ "gh:" "github:" ];
        "https://gitlab.com/".insteadOf = [ "gl:" "gitlab:" ];
        "https://sr.ht/".insteadOf = [ "srht:" "sourcehut:" ];
      };

      # On condition that a graphical environment is running, as presumed by the
      # presence of OpenGL or Vulkan, configure for Keepassxc password manager
      # support. Will not work on WSL without also installing Keepassxc, and running
      # it from WSL, but that's fine.
      credential.helper =
        lib.mkIf
          (with config.hardware; opengl.enable or opengl.driSupport)
          "${pkgs.git-credential-keepassxc}/bin/git-credential-keepassxc --git-groups";

      user = {
        name = "Gediminas Valys";
        email = "steamykins@gmail.com";
      };
    };
  };

  services.timesyncd.servers = [
    "1.europe.pool.ntp.org"
    "1.lt.pool.ntp.org"
    "2.europe.pool.ntp.org"
  ];

  nix = {
    package = pkgs.nixVersions.unstable;

    settings = {
      # Setting $NIX_PATH to Flake-provided nixpkgs allows repl and other
      # channel-dependent programs to use the correct nixpkgs.
      nix-path = [ "nixpkgs=${pkgs.path}" ];

      experimental-features = [
        "auto-allocate-uids" # Don't create `nixbld*` user accounts for builds.
        "cgroups" # Allow Nix to execute builds inside cgroups.
        "flakes" # Enable flakes.
        "nix-command" # Enable `nix {build,repl,shell,develop,...}` subcommands.
        "no-url-literals" # Disallow unquoted URLs in Nix language syntax.
        "repl-flake" # Allow passing installables to `nix repl`.
      ];
      auto-allocate-uids = true;
      use-cgroups = true;

      # TODO: Make configuration buildable with IFD disabled.
      # allow-import-from-derivation = false; # Disable IFD by default.
      flake-registry = pkgs.writeText "flake-registry.json" (builtins.toJSON {
        flakes = [];
        version = 2;
      });
      use-xdg-base-directories = true; # Don't clutter $HOME.
    };

    registry.nixpkgs = {
      from = { type = "indirect"; id = "nixpkgs"; };
      flake = self.inputs.nixpkgs;
    };
  };

  security.sudo = {
    # Only enable sudo by default if we have at least 1 non-system user.
    enable = lib.mkDefault
      (lib.filterAttrs (_: user: user.isNormalUser) config.users.users != { });

    wheelNeedsPassword = false;
  };
}
