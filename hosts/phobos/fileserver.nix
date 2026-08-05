{
  imports = [
    ../../profiles/nfs-share.nix
    ./acme.nix
  ];

  # NOTE: nginx requires execute permissions for traversal.
  fileSystems."/srv/http/static" = {
    device = "/mnt/box/uploads";
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
