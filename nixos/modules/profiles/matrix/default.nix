{ config, pkgs, lib, ... }:

# Reminder not to lose the matrix_key.pem file.
# If running stateless, ensure /state/run/keys/dendrite/matrix_key.pem
# is present and dendrite has perms to read it

{
  environment.persistence."/state" = {
    directories = [
      {
        directory = "/var/lib/acme";
        user = "acme";
        group = "acme";
        mode = "u=rwx,g=rx,o=x";
      }
      {
        directory = "/var/lib/postgresql";
        user = "postgres";
        group = "postgres";
        mode = "u=rwx,g=rx,o=x";
      }
    ];
    files = [{
      file = "/run/keys/dendrite/matrix_key.pem";
      parentDirectory = {
        user = "dendrite";
        group = "dendrite";
        mode = "0700";
      };
    }];
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 ];
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "steamykins@gmail.com";
    certs."${config.services.dendrite.settings.global.server_name}".postRun = ''
      systemctl reload nginx.service; systemctl restart dendrite.service
    '';
  };

  # dendrite.service has a dynamic user, but we need it to exist before service
  # is run to assign ownership of dirs/keys
  users = {
    groups.dendrite = { };
    users.dendrite = {
      isSystemUser = true;
      group = "dendrite";
      # Allow access to /run/keys for matrix_key.pem
      extraGroups = [ "keys" ];
    };
  };

  # Dendrite may try loading after postgresql, failing before it can connect
  systemd.services.dendrite.after = [ "postgresql.service" ];

  services = let
    server_name = "0x6776.lt";
    dbNames = [
      "app_service_api__database"
      "federation_api__database"
      "key_server__database"
      "media_api__database"
      "room_server__database"
      "sync_api__database"
      "user_api__account_database"
      "mscs__database"
    ];
    mergeAttrs = lib.foldl (a: b: a // b) { };
    dbAttrs = mergeAttrs (builtins.map (db:
      lib.setAttrByPath (lib.splitString "__" db) {
        connection_string =
          "postgres://dendrite@/dendrite_${db}?host=/run/postgresql";
      }) dbNames);
    dbPerms = mergeAttrs
      (builtins.map (db: { "DATABASE dendrite_${db}" = "ALL PRIVILEGES"; })
        dbNames);
    psqlInitScript = pkgs.writeText "postgresql-initScript" ''
      CREATE USER dendrite;
      ${lib.concatStringsSep "\n" (builtins.map (db: ''
        CREATE DATABASE dendrite_${db};
        GRANT ALL PRIVILEGES ON DATABASE dendrite_${db} TO dendrite;
      '') dbNames)}
    '';
  in {
    nginx = {
      enable = true;

      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

      virtualHosts.${server_name} = {
        enableACME = true;
        forceSSL = true;
        locations = {
          "/_matrix".proxyPass = "http://127.0.0.1:8008";

          "/.well-known/matrix/server".return = ''
            200 '{ "m.server": "${server_name}:443" }'
          '';

          "/.well-known/matrix/client".return = ''
            200 '{ "m.homeserver": { "base_url": "https://${server_name}" } }'
          '';
        };
      };
    };

    dendrite = {
      enable = true;

      settings = dbAttrs // {
        global = {
          inherit server_name;
          # Generate a private_key using:
          # $ nix shell nixpkgs#dendrite --command generate-keys --private-key matrix_key.pem
          private_key = "/run/keys/dendrite/matrix_key.pem";
          trusted_third_party_id_servers = [ "matrix.org" "vector.im" ];
          key_validity_period = "168h0m0s";
          disable_federation = false;
        };

        client_api.registration_disabled = true;
      };
    };

    postgresql = {
      enable = true;
      package = pkgs.postgresql_14;
      dataDir = "/var/lib/postgresql";

      initialScript = psqlInitScript;
      ensureDatabases = dbNames;
      ensureUsers = [{
        name = "dendrite";
        ensurePermissions = dbPerms;
      }];

      # Allow local connections via UNIX socket by user 'dendrite'
      authentication = lib.concatStringsSep "\n"
        (builtins.map (db: "local dendrite_${db} dendrite peer") dbNames);
    };
  };
}
