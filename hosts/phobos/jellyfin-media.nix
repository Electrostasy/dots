{ config, lib, ... }:

# Host-specific configuration to handle devices for jellyfin

lib.mkIf config.services.jellyfin.enable {
  # Retain jellyfin configuration between boots
  fileSystems."/var/lib/jellyfin" = {
    device = "/state/var/lib/jellyfin";
    fsType = "none";
    options = [ "bind" ];
  };

  # If we lose any of the required mounts, stop jellyfin
  systemd.services.jellyfin = {
    after = [ "fs.target" ];
    requires = [
      "var-lib-jellyfin.mount"
      "mnt-jellyfin-anime.mount"
      "mnt-jellyfin-shows.mount"
      "mnt-jellyfin-movies.mount"
    ];
  };

  # TODO: when setting up rtorrent and other services to work with jellyfin,
  # change these into bind-mounts

  # Automount the primary and backup external disks for media data
  fileSystems = let common = [ "noatime" "nodiratime" "noautodefrag" "compress=zstd" ]; in {
    "/mnt/jellyfin/anime" = {
      device = "/dev/disk/by-label/media";
      fsType = "btrfs";
      options = [ "subvol=anime" ] ++ common;
    };

    "/mnt/jellyfin/shows" = {
      device = "/dev/disk/by-label/media";
      fsType = "btrfs";
      options = [ "subvol=shows" ] ++ common;
    };

    "/mnt/jellyfin/movies" = {
      device = "/dev/disk/by-label/media";
      fsType = "btrfs";
      options = [ "subvol=movies" ] + common;
    };
  };
}
