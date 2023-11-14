{ config, pkgs, ... }:

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

    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts."sol.${config.networking.domain}" = {
      enableACME = true;
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://127.0.0.1:${builtins.toString config.services.headscale.port}";
        proxyWebsockets = true;
      };
    };
  };

  sops.secrets = {
    # Headscale does not support LoadCredential, so set permissions for the
    # secret accordingly.
    headscaleKey = {
      mode = "0440";
      owner = config.users.users.headscale.name;
      group = config.users.groups.headscale.name;
    };

    tailscaleKey = { };
  };

  environment.systemPackages = [ config.services.headscale.package ];
  services.headscale = {
    enable = true;

    address = "0.0.0.0";

    settings = {
      server_url = "https://sol.${config.networking.domain}";
      ip_prefixes = [ "100.64.0.0/10" ];

      # Generate new keys on a host running headscale using:
      # $ headscale generate private-key
      private_key_path = config.sops.secrets.headscaleKey.path;

      dns_config = {
        base_domain = config.networking.domain;
        domains = [ "sol.${config.networking.domain}" ];
        magic_dns = true;
        nameservers = [ "9.9.9.9" ];
        override_local_dns = true;
      };
    };
  };

  services.tailscale = {
    enable = true;

    openFirewall = true;
    useRoutingFeatures = "both";
    # Generate new keys on a host running headscale using:
    # $ headscale --user sol preauthkeys create --reusable --expiration 365d
    authKeyFile = config.sops.secrets.tailscaleKey.path;
    extraUpFlags = [
      "--advertise-exit-node"
      "--login-server" "https://sol.${config.networking.domain}"
    ];
  };

  # On a weekly basis, schedule old nodes for expiration.
  systemd.timers.headscale-expirenodes = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
      Unit = "headscale-expirenodes.service";
    };
  };

  systemd.services.headscale-expirenodes = {
    serviceConfig.Type = "oneshot";

    path = [
      config.services.headscale.package # headscale
      pkgs.jq # jq
    ];

    script = ''
      JQ_SCRIPT='map(select(.online != true and .expiry.seconds < 0 and now - .last_seen.seconds > 86400) | .id).[]'
      for ID in $(headscale nodes list -o json-line | jq -M "$JQ_SCRIPT"); do
        headscale nodes expire --identifier $ID
      done
    '';
  };

  # Ensure that the `sol` namespace always exists with the configured preauthkey.
  # If the namespace doesn't exist, create it and 'surgically' insert the key.
  # Does not remove other namespaces.
  systemd.services.headscale-namespacesetup = {
    after = [ "headscale.service" ];
    wants = [ "headscale.service" ];
    bindsTo = [ "headscale.service" ];
    wantedBy = [ "multi-user.target" ];

    path = [
      config.services.headscale.package # headscale
      config.systemd.package # systemd-creds
      pkgs.sqlite # sqlite3
    ];

    serviceConfig = {
      Type = "oneshot";
      LoadCredential = [ "tailscaleKey:${config.sops.secrets.tailscaleKey.path}" ];
    };

    script = ''
      NAMESPACES=($(headscale namespaces list | sed -r '/^\s*$/d;1d;$d' | cut -d'|' -f2 | tr -d ' '))
      if [ "$NAMESPACES" = 'sol' ]; then
        exit 0
      fi

      if [ -z "$NAMESPACES" ]; then
        headscale namespaces create sol

        QUERY='INSERT INTO pre_auth_keys '
        QUERY+='(key, user_id, reusable, created_at, expiration) '
        QUERY+='VALUES '
        QUERY+="('$(systemd-creds cat 'tailscaleKey')', 1, 1, datetime('now'), datetime('now', '+1 year'));"

        sqlite3 ${config.users.users.headscale.home}/db.sqlite "$QUERY"
      fi
    '';
  };
}
