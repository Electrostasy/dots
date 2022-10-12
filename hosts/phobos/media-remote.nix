let
  nfsMediaMount = export: {
    device = "10.10.1.5:/${export}";
    fsType = "nfs";
    options = [
      "nfsvers=4.2"
      "_netdev"
      "nofail"
      "x-systemd.automount"
      "x-systemd.idle-timeout=1800"
    ];
  };
in
{
  fileSystems = {
    "/mnt/media/anime" = nfsMediaMount "anime";
    "/mnt/media/movies" = nfsMediaMount "movies";
    "/mnt/media/music" = nfsMediaMount "music";
    "/mnt/media/shows" = nfsMediaMount "shows";
  };
}
