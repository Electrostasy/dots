{ config, pkgs, ... }:

{
  boot.kernelParams = [
    # IPv6 seems to (often silently) break Tailscale and DNS in various ways:
    # - unable to resolve public DNS servers (even on Tailscale clients after
    #   disconnecting)
    # - unable to resolve sol.0x6776.lt (even on this Pi)
    # - even flushing DNS caches doesn't fix this
    # - queries outside the VPN network show everything is fine
    # Better to just take a big hammer and disable it for all interfaces, save
    # myself the trouble.
    # NOTE: `ipv6.disable=1`, which disables the IPv6 stack in general, does NOT
    # fix this, apparently.
    "net.ipv6.conf.all.disable_ipv6=1"
  ];

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

  sops.secrets.headscaleKey = {
    mode = "0440";
    owner = config.users.users.headscale.name;
    group = config.users.groups.headscale.name;
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

      # Remove ephemeral nodes as soon as possible (1m5s is non-inclusive minimum).
      ephemeral_node_inactivity_timeout = "1m6s";

      dns_config = {
        base_domain = config.networking.domain;
        magic_dns = true;
      };
    };
  };

  services.tailscale = {
    enable = true;

    openFirewall = true;
    useRoutingFeatures = "both";
    extraUpFlags = [ "--advertise-exit-node" ];
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
      namespaces=($(headscale namespaces list | sed -r '/^\s*$/d;1d;$d' | cut -d'|' -f2 | tr -d ' '))
      if [ "$namespaces" = 'sol' ]; then
        exit 0
      fi

      if [ -z "$namespaces" ]; then
        headscale namespaces create sol

        query='INSERT INTO pre_auth_keys '
        query+='(key, user_id, ephemeral, created_at, expiration) '
        query+='VALUES '
        query+="('$(systemd-creds cat 'tailscaleKey')', 1, 1, datetime('now'), datetime('now', '+1 year'));"

        sqlite3 ${config.users.users.headscale.home}/db.sqlite "$query"
      fi
    '';
  };
}
