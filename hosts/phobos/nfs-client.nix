{ config, lib, ... }:

let
  fsRoot = "/mnt/media";
  host = "phobos.local";
  mkMount = x: {
    "${fsRoot}/${x}" = {
      device = "${host}:/${x}";
      fsType = "nfs";
      options = [ "nfsvers=4.2" ];
    };
  };
  mkMounts = xs: lib.foldl (a: b: a // b) { } (builtins.map mkMount xs);
  mounts = mkMounts [ "anime" "shows" "movies" "music" ];
in { fileSystems = mounts; }
