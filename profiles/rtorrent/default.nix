{ config, pkgs, ... }:

{
  services.rtorrent = {
    enable = true;
    dataDir = "/rtorrent/data";
    downloadDir = "/rtorrent/downloads";
  };

  # Expose rtorrent RPC socket
  services.nginx = {
    enable = true;
    virtualHosts."localhost" = {
      locations."^~ /rtorrent" = {
        extraConfig = ''
          include ${pkgs.nginx}/conf/scgi_params;
          scgi_pass unix:${config.services.rtorrent.rpcSocket};
        '';
      };
    };
  };

  # Allow `rtorrent` and `nginx` users to share the rtorrent RPC socket
  users = {
    groups = { rtorrent-sock = {}; };
    users = {
      rtorrent.extraGroups = [ "rtorrent-sock" ];
      nginx.extraGroups = [ "rtorrent-sock" ];
    };
  };
  services.rtorrent.configText = ''
    schedule = scgi_group,0,0,"execute.nothrow=chown,\":rtorrent-sock\",(cfg.rpcsock)"
  '';
}

