{ config, pkgs, lib, modulesPath, flake, ... }:

let
  hasSecrets = config.sops.secrets != { };
in

{
  imports = [ "${modulesPath}/profiles/perlless.nix" ];

  system = {
    configurationRevision = flake.rev or "dirty"; # for `nixos-version`.

    forbiddenDependenciesRegexes = lib.mkForce []; # override perlless profile.

    nixos-init.enable = true;
  };

  sops = {
    age = {
      keyFile = "/var/lib/sops-nix/keys.txt";
      sshKeyPaths = [ ];
    };

    gnupg.sshKeyPaths = [ ];
  };

  nix = {
    package = pkgs.nixVersions.latest;

    settings = {
      # Do not download a global flake registry, we use the system registry set
      # up by NixOS where `nixpkgs` is pinned.
      flake-registry = pkgs.writers.writeJSON "global-registry.json" {
        version = 2;
        flakes = [ ];
      };

      use-xdg-base-directories = true; # don't clutter $HOME.

      experimental-features = [
        "cgroups" # allow Nix to execute builds inside cgroups.
        "flakes" # enable flakes.
        "nix-command" # enable `nix {build,repl,shell,develop,...}` subcommands.
        "no-url-literals" # disallow unquoted URLs in Nix language syntax.
      ];

      use-cgroups = true;

      # When deploying NixOS configurations with `nixos-rebuild --target-host`,
      # we can get an error about missing valid signatures for store paths
      # built on the build host:
      # https://github.com/NixOS/nix/issues/2127#issuecomment-1465191608
      trusted-users = [ "@wheel" ];

      # Avoid the caller sending stuff over SSH to the builder when the builder
      # can fetch it themselves.
      builders-use-substitutes = true;
    };
  };

  nixpkgs = {
    config.allowAliases = false; # aliases bother me.
    overlays = [
      flake.overlays.default # include self-packaged packages.
    ];
  };

  boot = {
    tmp.useTmpfs = true;

    kernel.sysfs = {
      module.zswap.parameters = lib.mkIf (!config.zramSwap.enable) {
        enabled = true;
        zpool = "zsmalloc";
        compressor = "lz4";
      };
    };
  };

  time.timeZone = "Europe/Vilnius";

  # Set ISO-8601 datetime except for WSL where setlocale fails.
  i18n.extraLocaleSettings.LC_TIME = lib.mkIf (!config.wsl.enable) "en_DK.UTF-8";

  networking = {
    domain = "0x6776.lt";

    nameservers = [
      "9.9.9.9"
      "1.1.1.1"
    ];

    timeServers = [
      "1.europe.pool.ntp.org"
      "1.lt.pool.ntp.org"
      "2.europe.pool.ntp.org"
    ];

    # This defaults to true because of `networking.networkmanager`.
    # Use 999 for a higher priority than the default 1000.
    modemmanager.enable = lib.mkOverride 999 false;

    networkmanager = {
      wifi.backend = lib.mkDefault "iwd";

      # Disable IWD's autoconnect mechanism to have only NetworkManager
      # initiate connections. If left up to IWD, it will never autoconnect to
      # any networks configured through the NetworkManager NixOS option
      # `ensureProfiles`.
      settings = lib.mkIf (config.networking.networkmanager.wifi.backend == "iwd") {
        device."wifi.iwd.autoconnect" = false;
      };
    };

    useNetworkd = lib.mkDefault true; # translate `networking.*` into `systemd.network`.
    useDHCP = lib.mkDefault true;
  };

  # Only one can be enabled, otherwise we will run into errors saying we have
  # no network.
  systemd.network.wait-online.enable = !(config.networking.networkmanager.enable && config.systemd.services.NetworkManager-wait-online.enable);

  security.sudo.wheelNeedsPassword = false;

  environment = {
    # We do not need an explanation why we cannot run dynamically linked,
    # unpatched binaries on NixOS.
    stub-ld.enable = lib.mkDefault false;

    # Tell `sops` where to find the private key.
    sessionVariables.SOPS_AGE_KEY_FILE = lib.mkIf hasSecrets config.sops.age.keyFile;

    systemPackages = lib.mkIf hasSecrets [
      pkgs.rage
      pkgs.sops
    ];
  };

  preservation.preserveAt = {
    "/persist/cache" = {
      commonMountOptions = [ "x-gvfs-hide" ];

      users = {
        root = {
          home = "/root";
          directories = [ ".cache/nix" ];
        };

        electro = {
          directories = [ ".cache/nix" ];
        };
      };
    };

    "/persist/state" = {
      commonMountOptions = [ "x-gvfs-hide" ];

      directories = [
        "/etc/nixos"
        "/var/lib/nixos"
        "/var/lib/systemd"
        "/var/log/journal"
        (lib.mkIf hasSecrets { directory = builtins.dirOf config.sops.age.keyFile; inInitrd = true; })
      ];

      files = [
        { file = "/etc/machine-id"; inInitrd = true; how = "symlink"; configureParent = true; }
      ];
    };
  };

  systemd.services.systemd-machine-id-commit = lib.mkIf config.preservation.enable {
    unitConfig.ConditionPathIsMountPoint = [
      "" "/persist/state/etc/machine-id"
    ];

    serviceConfig.ExecStart = [
      "" "systemd-machine-id-setup --commit --root /persist/state"
    ];
  };

  programs.git = {
    enable = true;

    config = {
      url = {
        "https://github.com/".insteadOf = [ "gh:" "github:" ];
        "https://gitlab.com/".insteadOf = [ "gl:" "gitlab:" ];
        "https://sr.ht/".insteadOf = [ "srht:" "sourcehut:" ];
      };

      user = {
        name = "Gediminas Valys";
        email = "steamykins@gmail.com";
      };

      # Since git 2.35.2 this workaround is needed to fix an annoying error
      # when using `git` or `nixos-rebuild` as non-root in /etc/nixos:
      # fatal: detected dubious ownership in repository at '/etc/nixos'
      safe.directory = "/etc/nixos";
    };
  };

  users.mutableUsers = lib.mkDefault false;
}
