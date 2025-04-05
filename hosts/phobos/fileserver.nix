{ config, pkgs, ... }:

{
  networking.firewall = {
    enable = true;

    allowedTCPPorts = [
      80
      443
    ];
  };

  fileSystems."/srv/http/static" = {
    device = "/dev/disk/by-label/pidata";
    fsType = "btrfs";
    options = [
      "subvol=static"
      "noatime"
      "compress-force=zstd:1"
      "discard=async"
      "X-mount.owner=${config.users.users.electro.name}"
      "X-mount.group=${config.users.groups.users.name}"
    ];
  };

  # `rsync` has to be installed on the remote in order for uploads initialized
  # with it to work (such as `phobos-up` script).
  environment.systemPackages = [ pkgs.rsync ];

  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;

    virtualHosts.${config.networking.domain} = {
      enableACME = true;
      forceSSL = true;

      locations."/static" = {
        root = "/srv/http";
        tryFiles = "$uri =404";
      };
    };
  };
}
