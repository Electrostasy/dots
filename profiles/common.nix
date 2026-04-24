{ config, pkgs, lib, modulesPath, flake, ... }:

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

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 15d";
    };

    settings = {
      # Do not download a global flake registry, we use the system registry set
      # up by NixOS where `nixpkgs` is pinned.
      flake-registry = pkgs.writers.writeJSON "global-registry.json" {
        version = 2;
        flakes = [ ];
      };

      experimental-features = [
        "flakes"
        "nix-command"
      ];

      # When deploying NixOS configurations with `nixos-rebuild --target-host`,
      # we can get an error about missing valid signatures for store paths
      # built on the build host:
      # https://github.com/NixOS/nix/issues/2127#issuecomment-1465191608
      trusted-users = [ "@wheel" ];

      auto-optimise-store = true;
      builders-use-substitutes = true;
      trace-import-from-derivation = true;
      use-xdg-base-directories = true;
    };
  };

  nixpkgs = {
    config.allowAliases = false;
    overlays = [
      flake.outputs.overlays.packages
    ];
  };

  boot = {
    tmp.useTmpfs = true;

    kernelParams = [ "rootflags=noatime" ];

    kernel.sysfs = {
      module.zswap.parameters = lib.mkIf (!config.zramSwap.enable) {
        enabled = true;
        zpool = "zsmalloc";
        compressor = "lz4";
      };
    };
  };

  time.timeZone = "Europe/Vilnius";

  i18n = {
    defaultLocale = "lt_LT.UTF-8";

    extraLocaleSettings = {
      LC_MESSAGES = "en_US.UTF-8";
      LC_TIME = "en_DK.UTF-8";
    };
  };

  networking = {
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

  environment = {
    # We do not need an explanation why we cannot run dynamically linked,
    # unpatched binaries on NixOS.
    stub-ld.enable = lib.mkDefault false;

    # Tell `sops` where to find the private key.
    sessionVariables.SOPS_AGE_KEY_FILE = config.sops.age.keyFile;
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
        { directory = dirOf config.sops.age.keyFile; inInitrd = true; }
      ];

      files = [
        {
          file = "/etc/machine-id";
          inInitrd = true;
          how = "symlink";
          configureParent = true;
          createLinkTarget = true;
        }
      ];
    };
  };

  # As of systemd v258, /etc/machine-id cannot be created at first boot if it
  # points to a non-existent file:
  # https://github.com/systemd/systemd/issues/39717
  boot.initrd.systemd.tmpfiles.settings.preservation = lib.mkIf config.preservation.enable {
    "/sysroot/persist/state/etc/machine-id".f = {
      argument = "uninitialized";
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

  # Fontconfig is enabled by default even on headless systems.
  fonts.fontconfig.enable = lib.mkDefault config.services.graphical-desktop.enable;

  users.mutableUsers = lib.mkDefault false;
}
