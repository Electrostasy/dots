{ config, ... }:

{
  sops.secrets.netbird_datastore_key = { };

  preservation.preserveAt."/persist/state".directories = [
    config.services.netbird.server.management.settings.Datadir
  ];

  security.acme.certs."0x6776.lt" = {
    extraDomainNames = [ config.services.netbird.server.domain ];
    postRun = ''
      systemctl --no-block restart netbird-management netbird-signal netbird-relay
    '';
  };

  services.netbird.server = {
    enable = true;

    domain = "0x6e62.0x6776.lt";

    management = {
      dnsDomain = "internal.0x6776.lt";
      settings = {
        Stuns = [
          { Proto = "udp"; URI = "stun:0x6e62.0x6776.lt:3478"; }
        ];

        Relay = {
          Addresses = [ "rels://0x6e62.0x6776.lt:443" ];
          CredentialsTTL = "24h";
          Secret = {
            _secret = "/run/credentials/netbird-management.service/relay.key";
          };
        };

        DataStoreEncryptionKey = {
          _secret = "/run/credentials/netbird-management.service/datastore.key";
        };
      };
    };

    coturn.enable = false;
    dashboard.enable = false;
  };

  services.netbird.relay = {
    enable = true;

    authSecretFile = "/run/credentials/netbird-relay.service/relay.key";

    settings = {
      enable-stun = true;
      stun-ports = [ 3478 ];
      exposed-address = "rels://0x6e62.0x6776.lt:443";
    };
  };

  services.nginx = {
    upstreams = {
      netbird_management.servers = {
        "localhost:${toString config.services.netbird.server.management.port}" = { };
      };
      netbird_relay.servers = {
        "localhost:${toString config.services.netbird.relay.port}" = { };
      };
      netbird_signal.servers = {
        "localhost:${toString config.services.netbird.server.signal.port}" = { };
      };
      netbird_signal_ws.servers = {
        "localhost:8083" = { }; # TODO where is this port set?
      };
    };

    virtualHosts."0x6e62.0x6776.lt" = {
      recommendedProxySettings = true;

      extraConfig = ''
        grpc_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        client_header_timeout 1d;
        client_body_timeout 1d;
        grpc_read_timeout 1d;
        grpc_send_timeout 1d;
        grpc_socket_keepalive on;
      '';

      locations = {
        # Relay WebSocket.
        "/relay" = {
          proxyPass = "http://netbird_relay";
          proxyWebsockets = true;
        };

        # Signal WebSocket.
        "/ws-proxy/signal" = {
          proxyPass = "http://netbird_signal_ws";
          proxyWebsockets = true;
        };

        # Signal gRPC.
        "/signalexchange.SignalExchange/".extraConfig = ''
          grpc_pass grpc://netbird_signal;
        '';

        # Management API.
        "/api/" = {
          proxyPass = "http://netbird_management";
        };

        # Management WebSocket.
        "/ws-proxy/management" = {
          proxyPass = "http://netebird_management";
          proxyWebsockets = true;
        };

        # Management gRPC.
        "/management.ManagementService/".extraConfig = ''
          grpc_pass grpc://netbird_management
        '';
      };
    };
  };

  networking.firewall.allowedUDPPorts = [ 3478 ];

  systemd.services.netbird-management.serviceConfig = {
    after = [
      "acme-0x6776.lt.service"
      "nginx.service"
      "sops-install-secrets.service"
    ];

    wants = [
      "acme-0x6776.lt.service"
      "nginx.service"
      "sops-install-secrets.service"
    ];

    LoadCredential = [
      "relay.key:${config.sops.secrets.netbird_relay_key.path}"
      "datastore.key:${config.sops.secrets.netbird_datastore_key.path}"
    ];
  };

  systemd.services.netbird-relay.serviceConfig = {
    after = [
      "acme-0x6776.lt.service"
      "nginx.service"
      "sops-install-secrets.service"
    ];

    wants = [
      "acme-0x6776.lt.service"
      "nginx.service"
      "sops-install-secrets.service"
    ];

    LoadCredential = [
      "relay.key:${config.sops.secrets.netbird_relay_key.path}"
    ];
  };
}
