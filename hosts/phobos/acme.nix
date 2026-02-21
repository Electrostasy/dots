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

  services.nginx = {
    enable = true;

    # Enable https://letsencrypt.org/docs/challenge-types/#http-01-challenge.
    virtualHosts."0x6776.lt".enableACME = true;
  };

  networking.firewall.allowedTCPPorts = [ 80 ];
}
