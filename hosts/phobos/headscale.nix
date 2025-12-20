{ config, pkgs, ... }:

{
  sops.secrets = {
    headscaleKey = {
      mode = "0440";
      owner = config.users.users.headscale.name;
      group = config.users.groups.headscale.name;
    };

    tailscaleKey = { };
  };

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

    allowedTCPPorts = [ 80 443 ];
    allowedUDPPorts = [ 3478 ];
  };

  fileSystems."/var/lib/headscale" = {
    device = "/dev/disk/by-label/pidata";
    fsType = "btrfs";
    options = [
      "subvol=headscale"
      "noatime"
      "compress-force=zstd:1"
      "discard=async"
      "X-mount.owner=${config.users.users.headscale.name}"
      "X-mount.group=${config.users.groups.headscale.name}"
    ];
  };

  services.nginx = {
    enable = true;

    recommendedTlsSettings = true;

    virtualHosts."controlplane.${config.networking.domain}" = {
      enableACME = true;
      forceSSL = true;

      locations."/" = {
        recommendedProxySettings = false;

        proxyPass = "http://" + config.services.headscale.settings.listen_addr;
        proxyWebsockets = true;
        extraConfig = ''
          keepalive_requests 100000;
          keepalive_timeout 160s;
          proxy_buffering off;
          proxy_ignore_client_abort on;
          proxy_send_timeout 600s;
          proxy_read_timeout 900s;
          proxy_connect_timeout 75s;
          send_timeout 600s;
        '';
      };
    };
  };

  services.headscale = {
    enable = true;

    settings = {
      # Generate new keys on a host running headscale using:
      # $ headscale generate private-key
      private_key_path = config.sops.secrets.headscaleKey.path;

      server_url = "https://controlplane.${config.networking.domain}:443";

      dns = {
        base_domain = "sol.tailnet." + config.networking.domain;
        magic_dns = true;
        nameservers.global = [
          "9.9.9.9"
          "1.1.1.1"
        ];
      };

      derp = {
        server = {
          enabled = true;
          region_id = 999;
          verify_clients = true;
          region_code = "headscale";
          region_name = "controlplane.0x6776.lt";
          stun_listen_addr = "0.0.0.0:3478";
        };
        urls = [];
      };
    };
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

        sqlite3 ${config.users.users.headscale.home}/db.sqlite << EOF
INSERT INTO pre_auth_keys (key, user_id, reusable, ephemeral, created_at, expiration)
VALUES ('$(systemd-creds cat 'tailscaleKey')', 1, 1, 0, datetime('now'), datetime('now', '+1 year'));
EOF
      fi
    '';
  };
}
