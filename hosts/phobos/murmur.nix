{ config, pkgs, ... }:

{
  sops.secrets.murmurEnv = { };

  preservation.preserveAt."/persist/state".directories = [ config.services.murmur.stateDir ];

  security.acme.certs."0x6776.lt".postRun = ''
    ${pkgs.acl}/bin/setfacl -m u:${config.services.murmur.user}:rx ${config.security.acme.certs."0x6776.lt".directory}
    ${pkgs.acl}/bin/setfacl -m u:${config.services.murmur.group}:r ${config.security.acme.certs."0x6776.lt".directory}/{chain,cert,key}.pem
  '';

  services.murmur = {
    enable = true;

    environmentFile = "${config.sops.secrets.murmurEnv.path}";
    password = "$PASSWORD";

    port = 64738;
    openFirewall = true;

    tls.useACMEHost = "0x6776.lt";
  };
}
