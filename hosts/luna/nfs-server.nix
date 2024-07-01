{ config, pkgs, lib, ... }:

{
  environment.systemPackages = [ pkgs.smartmontools ];

  fileSystems."/srv/nfs" = {
    device = "/dev/disk/by-uuid/177e6dee-f31b-4b7c-842a-354433ac0d15";
    fsType = "bcachefs";
    options = [
      "compression=zstd"
      "replicas=3"
    ];
  };

  networking.firewall.allowedTCPPorts = [ 2049 ];

  services = {
    # Not needed for NFSv4.
    rpcbind.enable = lib.mkForce false;

    nfs = {
      server = {
        enable = true;
        createMountPoints = true;
        exports = ''
          /srv/nfs/ *.sol.${config.networking.domain}(rw,fsid=root,insecure)
        '';
      };

      settings.nfsd = {
        vers2 = false;
        vers3 = false;
      };
    };
  };
}
