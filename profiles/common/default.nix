{ config, pkgs, lib, modulesPath, flake, ... }:

{
  imports = [
    "${modulesPath}/profiles/perlless.nix"
    ./preservation.nix
    ./sops.nix
  ];

  system = {
    configurationRevision = flake.rev or "dirty"; # for `nixos-version`.

    forbiddenDependenciesRegexes = lib.mkForce []; # override perlless profile.
  };

  nix = {
    package = pkgs.nixVersions.latest;

    settings = {
      # Do not download a global flake registry, we use the system registry set
      # up by NixOS where `nixpkgs` is pinned.
      flake-registry = builtins.toFile "global-registry.json" (builtins.toJSON {
        version = 2;
        flakes = [  ];
      });

      use-xdg-base-directories = true; # don't clutter $HOME.

      experimental-features = [
        "cgroups" # allow Nix to execute builds inside cgroups.
        "flakes" # enable flakes.
        "nix-command" # enable `nix {build,repl,shell,develop,...}` subcommands.
        "no-url-literals" # disallow unquoted URLs in Nix language syntax.
      ];

      use-cgroups = true;
      build-dir = "/var/tmp";

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

  boot.tmp.useTmpfs = true;

  zswap = {
    enable = !config.zramSwap.enable;

    compressor = "lz4";
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

  # We do not need an explanation why we cannot run dynamically linked,
  # unpatched binaries on NixOS.
  environment.stub-ld.enable = lib.mkDefault false;

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
