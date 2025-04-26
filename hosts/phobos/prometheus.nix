{ config, ... }:

{
  fileSystems = {
    "/var/lib/${config.services.prometheus.stateDir}" = {
      device = "/dev/disk/by-label/pidata";
      fsType = "btrfs";
      options = [
        "subvol=prometheus"
        "noatime"
        "compress-force=zstd:1"
        "discard=async"
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
        "compress-force=zstd:1"
        "discard=async"
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

    exporters.node.enable = true;

    globalConfig = {
      # Recommended to set these to the same value for consistency.
      scrape_interval = "15s";
      evaluation_interval = config.services.prometheus.globalConfig.scrape_interval;
    };

    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = let inherit (config.services.prometheus.exporters.node) port; in [
          { targets = [ "localhost:${builtins.toString port}" ]; }
        ];
      }
    ];
  };

  services.nginx = {
    enable = true;

    # TODO: Serve on subdomain, might need a DNS with CNAME records.
    virtualHosts."${config.networking.hostName}.sol.tailnet.${config.networking.domain}" = {
      forceSSL = false;

      locations."/grafana/" = {
        recommendedProxySettings = true;
        proxyWebsockets = true;
        proxyPass = "http://localhost:${builtins.toString config.services.grafana.settings.server.http_port}";
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
          url = "http://localhost:${builtins.toString config.services.prometheus.port}";
          # Needs to match the scrape_interval or else $__rate_interval will break:
          # https://community.grafana.com/t/agent-scrape-interval-break-cpu-chart/110491/8
          jsonData.timeInterval = config.services.prometheus.globalConfig.scrape_interval;
        }
      ];
    };

    settings = {
      server = {
        # This block is only necessary when serving from a subpath or using oauth.
        domain = config.networking.hostName + ".sol.tailnet." + config.networking.domain;
        root_url = "%(protocol)s://%(domain)s:%(http_port)s/grafana/";
        serve_from_sub_path = true;
      };

      analytics = {
        reporting_enabled = false;
        feedback_links_enabled = false;
        check_for_plugin_updates = false;
      };
    };
  };
}
