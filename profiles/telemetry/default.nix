{ config, pkgs, lib, ... }:

{
  # Update using:
  # $ echo -n "telegraf:<password>" | base64
  sops.secrets.grafanaBasicAuth = {
    sopsFile = ./secrets.yaml;
    owner = config.users.users.telegraf.name;
    group = config.users.groups.telegraf.name;
  };

  networking.firewall.interfaces.${config.services.tailscale.interfaceName}.allowedTCPPorts = [
    9100
  ];

  services.telegraf = {
    enable = true;

    package = pkgs.telegraf.overrideAttrs {
      pname = "telegraf-with-plugins";

      # Build a minimal telegraf with only the defined plugins:
      # https://github.com/influxdata/telegraf/blob/719e3cbb3bcca0a00b0beacb6005312b0e0962ed/docs/CUSTOMIZATION.md
      tags = [ "custom" ] ++ lib.mapAttrsToListRecursiveCond
        (path: _: builtins.length path < 2)
        (path: _: lib.concatStringsSep "." path)
        (removeAttrs config.services.telegraf.extraConfig [ "agent" ]);

      doCheck = false; # customizing the build breaks tests.
    };

    environmentFiles = [ config.sops.secrets.grafanaBasicAuth.path ];

    extraConfig = {
      agent = {
        interval = "1s";
      };

      inputs = {
        cpu = [
          {
            totalcpu = false;
            collect_cpu_time = true;
          }
          {
            totalcpu = false;
            collect_cpu_time = true;
            interval = "500ms";
            name_suffix = "_live";
          }
        ];

        disk = [
          { ignore_mount_opts = [ "bind" ]; }
        ];

        diskio = [
          { }
          { interval = "500ms"; name_suffix = "_live"; }
        ];

        net = [
          { }
          { interval = "500ms"; name_suffix = "_live"; }
        ];

        mem = [
          { }
          { interval = "500ms"; name_suffix = "_live"; }
        ];

        temp = [
          { }
          { interval = "500ms"; name_suffix = "_live"; }
        ];
      };

      outputs = {
        prometheus_client = [
          {
            listen = ":9100";
            collectors_exclude = [
              "gocollector"
              "process"
            ];

            namepass = [ "cpu" "disk" "diskio" "net" "mem" "temp" ];
          }
        ];

        websocket = [
          {
            url = "ws://phobos.sol.tailnet.0x6776.lt/grafana/api/live/push/telegraf";
            data_format = "influx";
            flush_interval = "500ms";

            namepass = [ "*_live" ];

            headers = {
              Authorization = "Basic $GRAFANA_BASIC_AUTH";
            };
          }
        ];
      };
    };
  };
}
