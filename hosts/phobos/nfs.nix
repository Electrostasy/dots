{ config, lib, ... }:

let
  fsRoot = "/mnt/media";
  client = "mars.local";
  mkMount = x: {
    "${fsRoot}/${x}" = {
      device = "/dev/disk/by-label/media";
      fsType = "btrfs";
      options = let
        btrfs = [ "noatime" "nodiratime" "noautodefrag" "compress=zstd" ];
        automount = [ "noauto" "x-systemd.automount" "x-systemd.mount-timeout=30" ];
      in btrfs ++ automount ++ [ "subvol=${x}" ];
    };
  };
  mkMounts = xs: lib.foldl (a: b: a // b) { } (builtins.map mkMount xs);
  mounts = mkMounts [ "anime" "shows" "movies" "music" ];
in {
  fileSystems = mounts;
  networking.firewall.allowedTCPPorts = [ 2049 ];
  services.nfs.server = {
    enable = true;
    exports = let
      nfsRoot = "${fsRoot} ${client}(rw,fsid=0,insecure,no_subtree_check)";
      mkNfsMount = mount:
        "${mount} ${client}(rw,root_squash,nohide,insecure,no_subtree_check)";
    in lib.concatStrings (lib.intersperse "\n"
      ([ nfsRoot ] ++ builtins.map mkNfsMount (builtins.attrNames mounts)));
  };
  services.avahi = {
    publish.userServices = true;
    extraServiceFiles = lib.foldl lib.recursiveUpdate { } (builtins.map (mount:
      let
        export = lib.concatStringsSep "/" [ fsRoot mount ];
        escapedExport = lib.removePrefix "_" (builtins.replaceStrings [ "/" "." ] [ "_" "_" ] export);
      in {
        "${escapedExport}" = ''
          <?xml version="1.0" standalone='no'?>
          <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
          <service-group>
            <name replace-wildcards="yes">NFS share ${export}</name>
            <service>
              <type>_nfs._tcp</type>
              <port>2049</port>
              <txt-record>path=${export}</txt-record>
            </service>
          </service-group>
        '';
      }) (builtins.attrNames mounts));
  };
}
