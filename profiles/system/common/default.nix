{
  options,
  config,
  pkgs,
  lib,
  self,
  ...
}:

let
  modules = { };

  # Core system configuration, common across all NixOS hosts
  modules.core = {
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

    # LC_TIME is apparently not respected by `ls` and `lsd`, but `date` works.
    environment.sessionVariables.TIME_STYLE = "long-iso";

    nixpkgs = {
      overlays = builtins.attrValues self.overlays;
      config.allowAliases = false;
    };

    environment.defaultPackages = with pkgs; lib.mkForce [
      file
      ouch
      parted
    ];

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
          # Enable `nix` subcommands.
          "nix-command"
          # Enable flakes.
          "flakes"
          # Allow Nix to execute builds inside cgroups.
          "cgroups"
        ];
        use-cgroups = true;
        flake-registry = pkgs.writeText "flake-registry.json" (builtins.toJSON {
          flakes = [];
          version = 2;
        });
        # Don't clutter $HOME.
        use-xdg-base-directories = true;
      };

      registry.nixpkgs = {
        from = { type = "indirect"; id = "nixpkgs"; };
        flake = self.inputs.nixpkgs;
      };
    };
  };

  # Optional home-manager user configuration, may not necessarily be enabled.
  # Enable by adding `home-manager.nixosModule` to NixOS configuration.
  modules.home-manager = lib.optionalAttrs (options ? home-manager) {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      sharedModules = builtins.attrValues self.homeManagerModules ++ [
        # Manual adds a dependency on `nmd`, which breaks `nix flake check`
        # when checking NixOS configurations of other architectures, e.g.
        # running `nix flake check` on x86_64-linux for aarch64-linux.
        { manual.manpages.enable = false; }
      ];
    };

    # Makes assertions by Home-Manager easier to read when used as a NixOS
    # module, replacing 'user profile: ...' with 'user@hostname profile: ...'
    # and adding a Nix store path (probably because flakes are imported there).
    # TODO: Add warnings and possibly make these system-wide.
    assertions = with lib; mkOverride 20 (
      flatten (flip
        mapAttrsToList config.home-manager.users (u: c: flip
          builtins.map c.assertions (a: {
            inherit (a) assertion;
            message =
              let
                info = builtins.unsafeGetAttrPos "assertion" a;
                location = "${info.file}:${toString info.line}:${toString info.column}";
              in
                "${u}@${config.networking.hostName} profile${
                  if info != null then " in ${location}" else ""
                }: ${a.message}";
          }))));
  };

  # Optional sops-nix secrets configuration, may not necessarily be enabled.
  # Enable by adding `sops-nix.nixosModule` to NixOS configuration.
  modules.secrets = let keyFile = "/var/lib/sops-nix/keys.txt"; in
    lib.optionalAttrs (options ? sops) {
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

  # Optional opt-in state configuration, may not necessarily be enabled.
  # Enable by adding `impermanence.nixosModule` to NixOS configuration.
  modules.optionalState = lib.optionalAttrs (options.environment ? persistence) {
    # Persist the age private key if sops-nix is used for secrets management.
    # Does not work with impermanence, as it is not mounted early enough in the
    # boot process.
    fileSystems =
      let
        keyFileDir =
          lib.concatStringsSep "/"
            (lib.init (lib.splitString "/" config.sops.age.keyFile));
      in
        lib.optionalAttrs (options ? sops) {
          ${keyFileDir} = {
          device = "/state" + keyFileDir;
          fsType = "none";
          options = [ "bind" ];
          depends = [ "/state" ];
          neededForBoot = true;
        };
      };

    environment.persistence."/state" = {
      directories = [
        # NixOS configuration directory, used by `nixos-rebuild` etc.
        "/etc/nixos"

        # Kernel, system and other service messages/logs are stored here, which
        # can be useful to keep around between reboots.
        "/var/log"

        # NixOS uses dynamic users for systemd services wherever it can, it is
        # important to persist their UIDs and GIDs to not have corrupted state
        # on disk.
        "/var/lib/nixos"
      ]

      # Directories containing certificates that get signed and renewed.
      ++ lib.optionals
        (config.security.acme.certs != { })
          (builtins.attrValues (
            builtins.mapAttrs (_: v: {
              inherit (v) directory;
              user = "acme";
              group = "acme";
              mode = "u=rwx,g=rx,o=x";
            })
            config.security.acme.certs))

      # PostgreSQL databases
      ++ lib.optional
        config.services.postgresql.enable
        { directory = config.services.postgresql.dataDir;
          user = config.systemd.services.postgresql.serviceConfig.User;
          group = config.systemd.services.postgresql.serviceConfig.Group;
          mode = "u=rwx,g=rx,o=x";
        }

      # On systems without a RTC (e.g. a Raspberry Pi), the clock file can be
      # crucial for startup, for e.g. DNSSEC keys cannot be validated correctly
      # if the clock is wrong.
      ++ lib.optional
        (config.services.timesyncd.enable || config.services.chrony.enable)
        # /var/lib/systemd/timesync/clock mutates, which can cause issues when
        # it is a bind mount, so we persist its parent directory instead.
        "/var/lib/systemd/timesync";


      files = [
        # This file contains the unique machine ID of the local system,
        # commonly set during installation. Programs may use this ID to identify
        # the host with a globally unique ID in the network.
        "/etc/machine-id"
      ]

      # Contains the device-specific rotated Wireguard private key. If this is
      # not persistent, new devices from the associated Mullvad account have to
      # be removed each time the device is restarted.
      ++ lib.optionals
        config.services.mullvad-vpn.enable
        [ "/etc/mullvad-vpn/device.json"
          "/var/cache/mullvad-vpn/relays.json"
        ];
    };
  };
in
  lib.mkMerge (builtins.attrValues modules)
