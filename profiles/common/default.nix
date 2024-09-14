{ config, pkgs, lib, modulesPath, self, ... }:

{
  imports = (lib.attrValues self.nixosModules) ++ [
    self.inputs.nixos-wsl.nixosModules.wsl
    ./sops.nix
    ./impermanence.nix
    "${modulesPath}/profiles/perlless.nix"
    ./fixes.nix
  ];

  boot.tmp.useTmpfs = true;

  networking = {
    # Every host is to be considered part of this domain, however, only `phobos`
    # is internet-facing.
    domain = "0x6776.lt";

    nameservers = [
      # Quad9 DNS server:
      # https://www.quad9.net/
      "9.9.9.9"

      # Cloudflare DNS server:
      "1.1.1.1"
    ];

    # Use systemd-networkd by default.
    dhcpcd.enable = false;
    useDHCP = false;
    useNetworkd = true;
  };

  systemd.network.enable = true;

  # Sets up a VPN mesh overlay network "sol" across all hosts, connecting to the
  # control server running on `phobos`.
  sops.secrets = lib.mkIf config.services.tailscale.enable {
    tailscaleKey.sopsFile = ../../hosts/phobos/secrets.yaml;
  };

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
    ];
  };

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

  nixpkgs = {
    config.allowAliases = false;
    overlays = [
      self.overlays.default
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
          (config.services.xserver.enable or config.hardware.graphics.enable)
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

  security.sudo = {
    # Only enable sudo by default if we have at least 1 non-system user.
    enable = lib.mkDefault
      (lib.filterAttrs (_: user: user.isNormalUser) config.users.users != { });

    wheelNeedsPassword = false;
  };
}
