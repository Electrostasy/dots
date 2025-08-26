{ config, ... }:

{
  imports = [ ../luna/nfs-share.nix ];

  # NOTE: /mnt/luna/uploads needs execute permissions for nginx to be able to
  # traverse it!
  fileSystems."/srv/http/static" = {
    device = "/mnt/luna/uploads";
    options = [ "bind" ];
  };

  networking.firewall = {
    enable = true;

    allowedTCPPorts = [
      80
      443
    ];
  };

  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;

    virtualHosts.${config.networking.domain} = {
      enableACME = true;
      forceSSL = true;

      locations."/static" = {
        root = "/srv/http";
        tryFiles = "$uri $uri/ =404";
      };
    };
  };
}
