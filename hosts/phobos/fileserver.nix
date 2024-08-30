{ config, pkgs, ... }:

{
  # `rsync` has to be installed on the remote in order for uploads initialized
  # with it to work (such as `phobos-up` script).
  environment.systemPackages = [ pkgs.rsync ];

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
    recommendedTlsSettings = true;

    virtualHosts.${config.networking.domain} = {
      enableACME = true;
      forceSSL = true;

      locations."/static" = {
        root = "/srv/http";
        tryFiles = "$uri =404";
      };
    };
  };
}
