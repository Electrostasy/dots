{ config, ... }:

{
  fileSystems."/var/lib/acme" = {
    device = "/dev/disk/by-label/pidata";
    fsType = "btrfs";
    options = [
      "subvol=acme"
      "noatime"
      "compress-force=zstd:1"
      "discard=async"
      "X-mount.owner=${config.users.users.acme.name}"
      "X-mount.group=${config.users.groups.acme.name}"
    ];
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "steamykins@gmail.com";
  };
}
