{ config, pkgs, ... }:

{
  imports = [
    ./acme.nix
    ./postgresql.nix
  ];

  fileSystems."${config.services.prosody.dataDir}" = {
    device = "/dev/disk/by-label/pidata";
    fsType = "btrfs";
    options = [
      "subvol=prosody"
      "noatime"
      "X-mount.owner=${config.services.prosody.user}"
      "X-mount.group=${config.services.prosody.group}"
    ];
  };

  security.acme.certs."0x6776.lt" = {
    extraDomainNames = [
      "xmpp.0x6776.lt"
      "muc.0x6776.lt"
      "files.0x6776.lt"
    ];

    reloadServices = [ "prosody.service" ];

    postRun = ''
      ${pkgs.acl}/bin/setfacl -m u:prosody:rx /var/lib/acme/0x6776.lt
      ${pkgs.acl}/bin/setfacl -m u:prosody:r /var/lib/acme/0x6776.lt/{fullchain,key}.pem
    '';
  };

  services.prosody = {
    enable = true;

    package = pkgs.prosody.override {
      withExtraLuaPackages = ps: with ps; [ luadbi-postgresql ];
    };

    admins = [ "electro@0x6776.lt" ];

    s2sSecureAuth = true;

    ssl = {
      cert = "${config.security.acme.certs."0x6776.lt".directory}/fullchain.pem";
      key = "${config.security.acme.certs."0x6776.lt".directory}/key.pem";
    };

    virtualHosts."xmpp.0x6776.lt" = {
      enabled = true;

      domain = "0x6776.lt";
    };

    httpPorts = [ 5280 ];
    httpsPorts = [ 5281 ];

    extraConfig = ''
      c2s_ports = { 5222 }
      s2s_ports = { 5269 }
      c2s_direct_tls_ports = { 5223 }
      s2s_direct_tls_ports = { 5270 }

      storage = "sql"
      sql = {
        driver = "PostgreSQL",
        database = "prosody",
        username = "prosody",
        password = "",
        host = "/run/postgresql",
      }

      archive_expires_after = "never"
    '';

    muc = [
      {
        domain = "muc.0x6776.lt";
        restrictRoomCreation = true;
        maxHistoryMessages = 100;
      }
    ];

    httpFileShare = {
      domain = "files.0x6776.lt";
      http_external_url = "https://files.0x6776.lt/xmpp/";
    };
  };

  services.nginx = {
    enable = true;

    virtualHosts."files.0x6776.lt" = {
      forceSSL = true;
      useACMEHost = "0x6776.lt";

      locations."/xmpp" = {
        proxyPass = "http://127.0.0.1:5280/";
        recommendedProxySettings = true;
        extraConfig = ''
          proxy_buffering off;
          tcp_nodelay on;
        '';
      };
    };
  };

  services.postgresql = {
    ensureDatabases = [ "prosody" ];
    ensureUsers = [
      {
        name = "prosody";
        ensureDBOwnership = true;
        ensureClauses = {
          login = true;
        };
      }
    ];
  };

  systemd.services.prosody = {
    after = [
      "nginx.service"
      "postgresql.service"
    ];

    wants = [
      "nginx.service"
      "postgresql.service"
    ];
  };

  networking.firewall.allowedTCPPorts = [
    5222 # mod_c2s: client-to-server connections.
    5223 # mod_c2s: client-to-server connections over TLS.
    5269 # mod_s2s: server-to-server connections.
    5270 # mod_s2s: server-to-server connections over TLS.
    80
    443
  ];
}
