{ config, ... }:

{
  sops.secrets = {
    # NOTE: When updating the telegraf credentials, they need to be updated in
    # the profiles/telemetry module too! Update using:
    # $ openssl rand -base64 <length>
    # $ htpasswd -nb telegraf <password>
    nginxGrafanaHtpasswd = {
      owner = config.users.users.nginx.name;
      group = config.users.groups.nginx.name;
    };

    grafanaSecretKey = {
      owner = config.users.users.grafana.name;
      group = config.users.groups.grafana.name;
    };
  };

  fileSystems = {
    "/var/lib/${config.services.prometheus.stateDir}" = {
      device = "/dev/disk/by-label/pidata";
      fsType = "btrfs";
      options = [
        "subvol=prometheus"
        "noatime"
        "X-mount.owner=${config.users.users.prometheus.name}"
        "X-mount.group=${config.users.groups.prometheus.name}"
      ];
    };

    "${config.services.grafana.dataDir}" = {
      device = "/dev/disk/by-label/pidata";
      fsType = "btrfs";
      options = [
        "subvol=grafana"
        "noatime"
        "X-mount.owner=${config.users.users.grafana.name}"
        "X-mount.group=${config.users.groups.grafana.name}"
      ];
    };
  };

  services.prometheus = {
    enable = true;

    globalConfig = {
      # Recommended to set these to the same value for consistency.
      scrape_interval = "15s";
      evaluation_interval = config.services.prometheus.globalConfig.scrape_interval;
    };

    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = [
          {
            targets = map (host: "${host}:9100") [
              "luna"
              "phobos"
              "terra"
            ];
          }
        ];
      }
    ];
  };

  services.nginx.virtualHosts."${config.networking.hostName}.sol.tailnet.0x6776.lt" = {
    forceSSL = false;

    locations."/grafana/" = {
      recommendedProxySettings = true;
      proxyWebsockets = true;
      proxyPass = "http://127.0.0.1:${toString config.services.grafana.settings.server.http_port}";
      basicAuthFile = config.sops.secrets.nginxGrafanaHtpasswd.path;

      # TODO: Set X-Webauth-Role, default is Viewer.
      extraConfig = ''
        proxy_set_header X-Remote-User $remote_user;
      '';
    };
  };

  services.grafana = {
    enable = true;

    provision = {
      enable = true;

      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://127.0.0.1:${toString config.services.prometheus.port}";
          isDefault = true;
          # Needs to match the scrape_interval or else $__rate_interval will break:
          # https://community.grafana.com/t/agent-scrape-interval-break-cpu-chart/110491/8
          jsonData.timeInterval = config.services.prometheus.globalConfig.scrape_interval;
        }
      ];
    };

    settings = {
      server = {
        # This block is only necessary when serving from a subpath or using oauth.
        domain = config.networking.hostName + ".sol.tailnet.0x6776.lt";
        root_url = "%(protocol)s://%(domain)s:%(http_port)s/grafana/";
        serve_from_sub_path = true;
      };

      security = {
        secret_key = "$__file{${config.sops.secrets.grafanaSecretKey.path}}";
      };

      analytics = {
        reporting_enabled = false;
        feedback_links_enabled = false;
        check_for_plugin_updates = false;
      };

      log = {
        mode = "console";
      };

      auth = {
        disable_login_form = true;
      };

      "auth.basic".enabled = false;

      "auth.proxy" = {
        enabled = true;
        header_name = "X-REMOTE-USER";
        header_property = "username";
        auto_sign_up = true;
        whitelist = "127.0.0.1";
      };

      help.enabled = false;
      profile.enabled = false;
      news.news_feed_enabled = false;
      metrics.enabled = false;
    };
  };
}
