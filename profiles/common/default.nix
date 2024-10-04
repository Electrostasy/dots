{ config, pkgs, lib, modulesPath, self, ... }:

{
  imports = (lib.attrValues self.nixosModules) ++ [
    self.inputs.nixos-wsl.nixosModules.wsl
    ./sops.nix
    ./impermanence.nix
    "${modulesPath}/profiles/perlless.nix"
    ./fixes.nix
  ];

  nixpkgs = {
    config.allowAliases = false;
    overlays = [ self.overlays.default ];
  };

  sops.secrets = lib.mkIf config.services.tailscale.enable {
    tailscaleKey.sopsFile = ../../hosts/phobos/secrets.yaml;
  };

  boot.tmp.useTmpfs = true;

  # Cannot mess with locales on WSL, so do not customize them there.
  i18n = lib.mkIf (!config.wsl.enable) {
    # We want European formatting for everything, while keeping the language
    # English. With this, we get ISO-8601 formatted dates, metric measurements,
    # the works, while keeping it English.
    defaultLocale = "en_DK.UTF-8";

    supportedLocales = [
      "en_DK.UTF-8/UTF-8"
      "ja_JP.UTF-8/UTF-8" # required for Japanese in filenames.
      "lt_LT.UTF-8/UTF-8"
    ];
  };

  time.timeZone = lib.mkDefault "Europe/Vilnius";

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

    useNetworkd = true;
  };

  systemd.network = {
    enable = true;

    wait-online.anyInterface = true;

    networks = {
      "99-local-dhcp" = {
        matchConfig.Name = [ "en*" "eth*" ];
        networkConfig.DHCP = "ipv4";
      };

      "99-wireless-dhcp" = {
        matchConfig.WLANInterfaceType = "station";
        dhcpV4Config.RouteMetric = 1025; # 1024 is default, so prefer wired if available.
      };
    };
  };

  security.sudo.wheelNeedsPassword = false;

  services.tailscale = {
    enable = lib.mkDefault true;

    # Generate new keys on the host running headscale using:
    # $ headscale --user sol preauthkeys create --ephemeral --expiration 1y
    authKeyFile = config.sops.secrets.tailscaleKey.path;
    extraUpFlags = [
      "--login-server" "https://sol.${config.networking.domain}"

      # https://tailscale.com/kb/1098/machine-names#renaming-a-machine-in-the-cli
      "--hostname" config.networking.hostName

      # On shutdowns, the nodes remain in headscale even if they are ephemeral.
      # Either a logout before shutdown, or a reauth on connect is necessary.
      "--force-reauth"
      "--reset"
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
}
