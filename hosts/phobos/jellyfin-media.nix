{ config, lib, pkgs, ... }:

# Host-specific configuration to handle devices for jellyfin

lib.mkIf config.services.jellyfin.enable {
  # Hardware acceleration
  hardware.opengl = {
    enable = true;
    driSupport = true;
  };

  services.jellyfin.package = pkgs.jellyfin.overrideAttrs (prev: {
    patches = prev.patches ++ [
      # Fix h264_v4l2m2m acceleration in Raspberry Pi 4
      (lib.fetchPatch {
        url = "https://github.com/jellyfin/jellyfin/pull/7227.patch";
        sha256 = "sha256-RR5Hf/XEfPE5oCK60+xT33rAB2e2yxNeHwG+d1euk1M=";
      })
    ];
  });

  users = let id = 995; in {
    groups.jellyfin.gid = id;
    users.jellyfin = {
      uid = id;
      extraGroups = [ "video" ]; # GPU support
    };
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
