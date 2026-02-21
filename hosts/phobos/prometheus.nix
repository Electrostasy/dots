{ config, ... }:

{
  sops.secrets.grafanaSecretKey = {
    owner = config.users.users.grafana.name;
    group = config.users.groups.grafana.name;
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

  networking.firewall = {
    enable = true;

    allowedTCPPorts = [ 80 ];
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

        # Relabel "instance" from "host:port" to "host":
        # https://github.com/prometheus/docs/issues/2296#issuecomment-1527133892
        relabel_configs = [
          {
            source_labels = [ "__address__" ];
            regex = "(.+):(\\d+)";
            target_label = "instance";
            replacement = "$1";
          }
        ];

        static_configs = [
          {
            targets = map (host: "${host}:${toString config.services.prometheus.exporters.node.port}") [
              "luna"
              "phobos"
              "terra"
            ];
          }
        ];
      }
    ];
  };

  services.nginx = {
    enable = true;

    # TODO: Serve on subdomain, might need a DNS with CNAME records.
    virtualHosts."${config.networking.hostName}.sol.tailnet.0x6776.lt" = {
      forceSSL = false;

      locations."/grafana/" = {
        recommendedProxySettings = true;
        proxyWebsockets = true;
        proxyPass = "http://localhost:${toString config.services.grafana.settings.server.http_port}";
      };
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
          url = "http://localhost:${toString config.services.prometheus.port}";
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
    };
  };
}
