{ config, pkgs, ... }:

{
  sops.secrets.matrix_key = {
    sopsFile = ./secrets.yaml;
    mode = "0700";
    owner = config.users.users.dendrite.name;
    inherit (config.users.users.dendrite) group;
  };

  networking.firewall = {
    enable = true;

    allowedTCPPorts = [ 80 443 ];
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "steamykins@gmail.com";
  };

  # dendrite.service has a dynamic user, but we need it to exist before service
  # is run to assign ownership of dirs/keys
  users = {
    groups.dendrite = { };
    users.dendrite = {
      isSystemUser = true;
      group = "dendrite";
    };
  };

  systemd.services.dendrite = {
    # Dendrite may try loading after postgresql, failing before it can connect
    after = [ "postgresql.service" ];

    # Allow access to /run/keys for matrix_key.pem
    serviceConfig.SupplementaryGroups = [ config.users.groups.keys.name ];
  };

  services.nginx = {
    enable = true;

    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts.${config.networking.fqdn} = {
      enableACME = true;
      forceSSL = true;
      locations = {
        "/_matrix".proxyPass = "http://127.0.0.1:8008";

        "/.well-known/matrix/server".return = ''
          200 '{ "m.server": "${config.networking.fqdn}:443" }'
        '';

        "/.well-known/matrix/client".return = ''
          200 '{ "m.homeserver": { "base_url": "https://${config.networking.fqdn}" } }'
        '';
      };
    };
  };

  services.dendrite = {
    enable = true;

    settings = {
      global = {
        # Generate a private_key using:
        # $ nix shell nixpkgs#dendrite --command generate-keys --private-key matrix_key.pem
        private_key = config.sops.secrets.matrix_key.path;
        server_name = config.networking.fqdn;
        database.connection_string = "postgres://dendrite@/dendrite?host=/run/postgresql&sslmode=disable";
        trusted_third_party_id_servers = [ "matrix.org" "vector.im" ];
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

      # Add new users using:
      # $ nix shell nixpkgs#dendrite --command create-account -config /run/dendrite/dendrite.yaml -username electro
      client_api.registration_disabled = true;

      logging = [
        { type = "std";
          level = "error";
        }
      ];
    };
  };

  services.postgresql = {
    enable = true;

    package = pkgs.postgresql_15;
    dataDir = "/var/lib/postgresql";

    ensureDatabases = [ "dendrite" ];
    ensureUsers = [
      { name = "dendrite";
        ensurePermissions = {
          "DATABASE \"dendrite\"" = "ALL PRIVILEGES";
        };
      }
    ];

    # Allow local connections via UNIX socket by user 'dendrite'
    authentication = ''
      local dendrite dendrite peer
    '';
  };
}
