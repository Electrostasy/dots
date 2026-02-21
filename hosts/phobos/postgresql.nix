{ config, ... }:

{
  fileSystems."${config.services.postgresql.dataDir}" = {
    device = "/dev/disk/by-label/pidata";
    fsType = "btrfs";
    options = [
      "subvol=postgresql"
      "noatime"
      "X-mount.owner=${config.users.users.postgres.name}"
      "X-mount.group=${config.users.groups.postgres.name}"
    ];
  };

  services.postgresql.enable = true;
}
