{ lib, ... }:

{
  fileSystems = {
    "/mnt/media" = {
      device = "/dev/disk/by-label/media";
      fsType = "btrfs";
      options = [
        "noatime" "nodiratime" "autodefrag" "commit=60" "compress-force=zstd:3"
      ];
    };

    "/mnt/media_backup" = {
      device = "/dev/disk/by-label/media_backup";
      fsType = "btrfs";
      options = [
        "noatime" "nodiratime" "autodefrag" "commit=60" "compress-force=zstd:3"
      ];
    };
  };

  services = {
    btrbk.instances.media-backup = {
      onCalendar = "daily";
      settings = {
        snapshot_dir = ".snapshots";
        snapshot_preserve = "3d 2w";
        snapshot_preserve_min = "1w";
        target_preserve = "3w 2m";
        target_preserve_min = "2w";
        preserve_day_of_week = "monday";

        volume."/mnt/media" = {
          target = "/mnt/media_backup";
          subvolume = {
            "anime" = { };
            "movies" = { };
            "music" = { };
            "shows" = { };
          };
        };
      };
    };

    # Not required for nfs v4
    rpcbind.enable = lib.mkForce false;
    nfs.server = {
      enable = true;
      extraNfsdConfig = ''
        vers2=n
        vers3=n
        vers4=y
        vers4.0=y
        vers4.1=y
        vers4.2=y
      '';
      # TODO: Hostname `mars.local` can't be resolved when the host is offline,
      # so nfs services will fail until the hostname is resolvable. In the
      # meantime, ssh into phobos.local and restart them on demand
      exports = ''
        /mnt/media mars.local(rw,fsid=0,insecure,no_subtree_check)
        /mnt/media/anime mars.local(rw,root_squash,nohide,insecure,no_subtree_check)
        /mnt/media/movies mars.local(rw,root_squash,nohide,insecure,no_subtree_check)
        /mnt/media/music mars.local(rw,root_squash,nohide,insecure,no_subtree_check)
        /mnt/media/shows mars.local(rw,root_squash,nohide,insecure,no_subtree_check)
      '';
    };

    avahi = {
      publish.userServices = true;
      extraServiceFiles = let
        nfsService = mount: ''
          <?xml version="1.0" standalone='no'?>
          <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
          <service-group>
            <name replace-wildcards="yes">NFS share /mnt/media/${mount}</name>
            <service>
              <type>_nfs._tcp</type>
              <port>2049</port>
              <txt-record>path=/mnt/media/${mount}</txt-record>
            </service>
          </service-group>
        '';
      in {
        "mnt-media-anime" = nfsService "anime";
        "mnt-media-movies" = nfsService "movies";
        "mnt-media-music" = nfsService "music";
        "mnt-media-shows" = nfsService "shows";
      };
    };
  };

  # Not required for nfs v4
  systemd.services.rpc-statd.enable = false;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 2049 ];
  };
}
