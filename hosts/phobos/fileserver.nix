{
  imports = [
    ../pandora/nfs-share.nix
    ./acme.nix
  ];

  # NOTE: /mnt/pandora/uploads needs execute permissions for nginx to be able to
  # traverse it!
  fileSystems."/srv/http/static" = {
    device = "/mnt/pandora/uploads";
    fsType = "none";
    options = [ "bind" ];
  };

  security.acme.certs."0x6776.lt".extraDomainNames = [ "files.0x6776.lt" ];

  services.nginx.virtualHosts."files.0x6776.lt" = {
    forceSSL = true;
    useACMEHost = "0x6776.lt";

    locations."/static" = {
      root = "/srv/http";
      tryFiles = "$uri $uri/ =404";
    };
  };
}
