{ config, pkgs, ... }:

{
  sops.secrets.murmurEnv = { };

  fileSystems."${config.services.murmur.stateDir}" = {
    device = "/dev/disk/by-label/pidata";
    fsType = "btrfs";
    options = [
      "subvol=murmur"
      "noatime"
      "X-mount.owner=${config.services.murmur.user}"
      "X-mount.group=${config.services.murmur.group}"
    ];
  };

  security.acme.certs."0x6776.lt" = {
    reloadServices = [ "murmur.service" ];

    postRun = ''
      ${pkgs.acl}/bin/setfacl -m u:${config.services.murmur.user}:rx /var/lib/acme/0x6776.lt
      ${pkgs.acl}/bin/setfacl -m u:${config.services.murmur.group}:r /var/lib/acme/0x6776.lt/{fullchain,cert,key}.pem
    '';
  };

  services.murmur = {
    enable = true;

    environmentFile = "${config.sops.secrets.murmurEnv.path}";
    password = "$PASSWORD";

    port = 64738;
    openFirewall = true;

    sslCa = "${config.security.acme.certs."0x6776.lt".directory}/fullchain.pem";
    sslCert = "${config.security.acme.certs."0x6776.lt".directory}/cert.pem";
    sslKey = "${config.security.acme.certs."0x6776.lt".directory}/key.pem";
  };
}
