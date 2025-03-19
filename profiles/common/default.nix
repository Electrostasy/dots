{ config, pkgs, lib, modulesPath, self, ... }:

{
  imports = [
    ./sops.nix
    ./impermanence.nix
    "${modulesPath}/profiles/perlless.nix"
    ./fixes.nix
  ];

  system = {
    configurationRevision = self.rev or "dirty"; # for `nixos-version`.
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
      self.overlays.default # include self-packaged packages.
      self.overlays.rkdeveloptool-update
    ];
  };

  boot.tmp.useTmpfs = true;

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

    useNetworkd = lib.mkDefault true; # translate `networking.*` options into `systemd.network`.
    useDHCP = lib.mkDefault true;
  };

  security.sudo.wheelNeedsPassword = false;

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
}
