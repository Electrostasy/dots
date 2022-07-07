let
  nfsMediaMount = export: {
    device = "phobos.local:/${export}";
    fsType = "nfs";
    options = [ "nfsvers=4.2" ];
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
