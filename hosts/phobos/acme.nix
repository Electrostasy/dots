{ config, ... }:

{
  fileSystems."/var/lib/acme" = {
    device = "/dev/disk/by-label/pidata";
    fsType = "btrfs";
    options = [
      "subvol=acme"
      "noatime"
      "X-mount.owner=${config.users.users.acme.name}"
      "X-mount.group=${config.users.groups.acme.name}"
    ];
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "steamykins@gmail.com";
  };

  services.nginx.virtualHosts."0x6776.lt" = {
    # Enable https://letsencrypt.org/docs/challenge-types/#http-01-challenge.
    enableACME = true;

    # Create an HTTPS server block in addition to HTTP.
    addSSL = true;
  };
}
