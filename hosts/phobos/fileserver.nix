{
  imports = [
    ../luna/nfs-share.nix
    ./acme.nix
  ];

  # NOTE: /mnt/luna/uploads needs execute permissions for nginx to be able to
  # traverse it!
  fileSystems."/srv/http/static" = {
    device = "/mnt/luna/uploads";
    options = [ "bind" ];
  };

  security.acme.certs."0x6776.lt".extraDomainNames = [ "files.0x6776.lt" ];

  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;

    virtualHosts."files.0x6776.lt" = {
      forceSSL = true;
      useACMEHost = "0x6776.lt";

      locations."/static" = {
        root = "/srv/http";
        tryFiles = "$uri $uri/ =404";
      };
    };
  };

  networking.firewall = {
    enable = true;

    allowedTCPPorts = [
      80
      443
    ];
  };
}
