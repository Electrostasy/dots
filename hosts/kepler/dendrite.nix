{ config, lib, ... }:

{
  networking.firewall = {
    enable = true;

    allowedTCPPorts = [
      80
      443
    ];
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "steamykins@gmail.com";
  };

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

      # Add new users on the host system using:
      # $ dendrite --command create-account -config /run/dendrite/dendrite.yaml -username electro
      client_api.registration_disabled = true;

      logging = [
        { type = "std";
          level = "error";
        }
      ];
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

    dataDir = "/var/lib/postgresql";
    ensureDatabases = [ "dendrite" ];
    ensureUsers = [
      { name = "dendrite";
        ensurePermissions = {
          "DATABASE \"dendrite\"" = "ALL PRIVILEGES";
        };
      }
    ];
  };

  # See https://github.com/NixOS/nixpkgs/pull/266270.
  systemd.services.postgresql.postStart = lib.mkAfter ''
    $PSQL -tAc 'ALTER DATABASE "dendrite" OWNER TO "dendrite";'
  '';
}
