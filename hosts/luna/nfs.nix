{ config, ... }:

{
  networking.firewall = {
    # Required for NFS3/4.
    allowedTCPPorts = [ 111 2049 4000 4001 4002 20048 ];
    allowedUDPPorts = [ 111 2049 4000 4001 4002 20048 ];
  };

  services.nfs = {
    server = {
      enable = true;

      exports = ''
        /srv/nfs/ *.sol.tailnet.${config.networking.domain}(rw,fsid=root,insecure,no_subtree_check)
        /srv/nfs/ 192.168.205.0/24(rw,fsid=0,insecure,no_subtree_check)
      '';
    };

    settings.nfsd = {
      vers2 = false;
      vers3 = true; # needed for mounting by Windows clients.
    };
  };
}
