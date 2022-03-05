{ config, lib, ... }:

let
  fsRoot = "/mnt/media";
  client = "mars";
  mkMount = x: {
    "${fsRoot}/${x}" = {
      device = "/dev/disk/by-label/media";
      fsType = "btrfs";
      options =
        let
          btrfs = [ "noatime" "nodiratime" "noautodefrag" "compress=zstd" ];
          automount = [ "noauto" "x-systemd.automount" "x-systemd.mount-timeout=30" ];
        in
        btrfs ++ automount ++ [ "subvol=${x}" ];
    };
  };
  mkMounts = xs: lib.foldl (a: b: a // b) {} (builtins.map mkMount xs);
  mounts = mkMounts [ "anime" "shows" "movies" "music" ];
in
{
  fileSystems = mounts;
  networking.firewall.allowedTCPPorts = [ 2049 ];
  services.nfs.server = {
    enable = true;
    exports = let
      nfsRoot = "${fsRoot} ${client}(ro,fsid=0,no_subtree_check)";
      mkNfsMount = mount:
        "${mount} ${client}(ro,root_squash,nohide,insecure,no_subtree_check)";
    in lib.concatStrings (
      lib.intersperse "\n" (
        [ nfsRoot ] ++ builtins.map mkNfsMount (builtins.attrNames mounts)
      )
    );
  };
}

