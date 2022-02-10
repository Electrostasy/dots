{ config, lib, ... }:

# Host-specific configuration to handle devices for jellyfin

lib.mkIf config.services.jellyfin.enable {
  users = {
    groups.jellyfin.gid = 995;
    users.jellyfin.uid = 995;
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

  fileSystems = let
    btrfs = [ "noatime" "nodiratime" "noautodefrag" "compress=zstd" ];
    automount = [ "noauto" "x-systemd.automount" "x-systemd.mount-timeout=30" ];
  in {
    # Retain jellyfin configuration between boots
    "/var/lib/jellyfin" = {
      device = "/state/var/lib/jellyfin";
      fsType = "none";
      options = [ "bind" ];
    };

    # TODO: when setting up rtorrent and other services to work with jellyfin,
    # change these into bind-mounts

    # Automount subvolumes
    "/mnt/jellyfin/anime" = {
      device = "/dev/disk/by-label/media";
      fsType = "btrfs";
      options = btrfs ++ automount ++ [ "subvol=anime" ];
    };

    "/mnt/jellyfin/shows" = {
      device = "/dev/disk/by-label/media";
      fsType = "btrfs";
      options = btrfs ++ automount ++ [ "subvol=shows" ];
    };

    "/mnt/jellyfin/movies" = {
      device = "/dev/disk/by-label/media";
      fsType = "btrfs";
      options = btrfs ++ automount ++ [ "subvol=movies" ];
    };
  };
}
