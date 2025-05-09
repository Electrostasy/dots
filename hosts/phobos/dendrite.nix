{ config, pkgs, lib, ... }:

{
  networking.firewall = {
    enable = true;

    allowedTCPPorts = [
      80
      443
    ];
  };

  fileSystems = {
    "/var/lib/dendrite" = {
      device = "/dev/disk/by-label/pidata";
      fsType = "btrfs";
      options = [
        "subvol=dendrite"
        "noatime"
        "compress-force=zstd:1"
        "discard=async"
      ];
    };

    "/var/lib/postgresql" = {
      device = "/dev/disk/by-label/pidata";
      fsType = "btrfs";
      options = [
        "subvol=postgresql"
        "noatime"
        "compress-force=zstd:1"
        "discard=async"
        "X-mount.owner=${config.users.users.postgres.name}"
        "X-mount.group=${config.users.groups.postgres.name}"
      ];
    };
  };

  # PostgreSQL systemd service hardening has "PrivateMounts" enabled, which
  # prevents the "ExecStartPre" script from symlinking the config file to the data
  # directory, our mountpoint that is now excluded from the service's mount namespace.
  # This allows the data directory mountpoint to be visible to the service again.
  systemd.services.postgresql.serviceConfig.ReadWritePaths = [ config.services.postgresql.dataDir ];

  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;

    virtualHosts.${config.networking.domain} = {
      enableACME = true;
      forceSSL = true;

      locations = {
        "/_matrix".proxyPass = "http://127.0.0.1:8008";

        "/.well-known/matrix/server".return = ''
          200 '{ "m.server": "${config.networking.domain}:443" }'
        '';

        "/.well-known/matrix/client".return = ''
          200 '{ "m.homeserver": { "base_url": "https://${config.networking.domain}" } }'
        '';
      };
    };
  };

  sops.secrets.matrix_key = { };

  environment.systemPackages = [ pkgs.dendrite ];

  services.dendrite = {
    enable = true;

    loadCredential = [ "private_key:${config.sops.secrets.matrix_key.path}" ];
    settings = {
      global = {
        # Generate a private_key using:
        # $ dendrite --command generate-keys --private-key matrix_key.pem
        private_key = "$CREDENTIALS_DIRECTORY/private_key";
        server_name = config.networking.domain;
        database.connection_string = "postgres://dendrite@/dendrite?host=/run/postgresql&sslmode=disable";
        key_validity_period = "168h0m0s";
        disable_federation = false;

        presence = {
          enable_inbound = true;
          enable_outbound = true;
        };
      };

      sync_api.search = {
        enabled = true;
        index_path = "/var/lib/dendrite/searchindex";
        language = "en";
      };

      # Have to explicitly disable these or else the global connection_string is
      # ignored, and dendrite creates sqlite databases:
      # https://github.com/NixOS/nixpkgs/pull/195376
      app_service_api.database.connection_string = "";
      federation_api.database.connection_string = "";
      key_server.database.connection_string = "";
      media_api.database.connection_string = "";
      mscs.database.connection_string = "";
      relay_api.database.connection_string = "";
      room_server.database.connection_string = "";
      sync_api.database.connection_string = "";
      user_api.account_database.connection_string = "";
      user_api.device_database.connection_string = "";

      # Add new users on the host system using (requires shared secret registration):
      # $ create-account -config /run/dendrite/dendrite.yaml -username electro
      client_api.registration_disabled = true;

      logging = [ { type = "std"; level = "error"; } ];
    };
  };

  # A system user needs to exist in order for peer authentication over UNIX
  # socket to postgresql to work.
  users = {
    groups.dendrite = { };
    users.dendrite = {
      isSystemUser = true;
      group = config.users.groups.dendrite.name;
    };
  };

  systemd.services.dendrite = {
    # Dendrite may try loading after postgresql, failing before it can connect.
    after = [ "postgresql.service" ];

    serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = config.users.users.dendrite.name;
      Group = config.users.groups.dendrite.name;
    };
  };

  services.postgresql = {
    enable = true;

    package = pkgs.postgresql_16;

    ensureDatabases = [ "dendrite" ];
    ensureUsers = [
      { name = "dendrite";
        ensureDBOwnership = true;
      }
    ];
  };
}
