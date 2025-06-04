{ config, pkgs, lib, modulesPath, flake, ... }:

{
  imports = [
    "${modulesPath}/profiles/perlless.nix"
    ./fixes.nix
    ./preservation.nix
    ./sops.nix
  ];

  system = {
    configurationRevision = flake.rev or "dirty"; # for `nixos-version`.

    rebuild.enableNg = true;
  };

  nix = {
    package = pkgs.nixVersions.latest;

    settings = {
      use-xdg-base-directories = true; # don't clutter $HOME.

      experimental-features = [
        "cgroups" # allow Nix to execute builds inside cgroups.
        "flakes" # enable flakes.
        "nix-command" # enable `nix {build,repl,shell,develop,...}` subcommands.
        "no-url-literals" # disallow unquoted URLs in Nix language syntax.
      ];

      use-cgroups = true;
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

  i18n.extraLocaleSettings.LC_TIME = "en_DK.UTF-8"; # ISO-8601 datetime.

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

    networkmanager.wifi.backend = lib.mkDefault "iwd";
    useNetworkd = lib.mkDefault true; # translate `networking.*` options into `systemd.network`.
    useDHCP = lib.mkDefault true;
  };

  security.sudo.wheelNeedsPassword = false;

  preservation.preserveAt."/persist/state".users.electro.files = [
    (lib.optionalString config.services.graphical-desktop.enable ".config/git-credential-keepassxc")
  ];

  programs.git = {
    enable = true;

    config = {
      url = {
        "https://github.com/".insteadOf = [ "gh:" "github:" ];
        "https://gitlab.com/".insteadOf = [ "gl:" "gitlab:" ];
        "https://sr.ht/".insteadOf = [ "srht:" "sourcehut:" ];
      };

      credential.helper =
        lib.mkIf
          config.services.graphical-desktop.enable
          "${lib.getExe pkgs.git-credential-keepassxc} --git-groups";

      user = {
        name = "Gediminas Valys";
        email = "steamykins@gmail.com";
      };
    };
  };

  users.mutableUsers = lib.mkDefault false;
}
