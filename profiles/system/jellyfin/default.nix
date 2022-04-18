{ config, ... }:

{
  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;

    upstreams."jellyfin".servers = {
      "127.0.0.1:8096" = {};
    };

    virtualHosts = {
      "127.0.0.1" = {
        locations = {
          "/".proxyPass = "http://jellyfin";
        };
      };
    };
  };
}
