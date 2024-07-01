{ lib, ... }:

{
  fileSystems."/mnt/luna" = {
    device = "luna:/";
    fsType = "nfs4";
    options = [
      "noatime"
      "nofail"
      "x-systemd.automount"
      "x-gvfs-show"
      "x-gvfs-icon=folder-remote"
      "x-gvfs-symbolic-icon=folder-remote-symbolic"
      "x-gvfs-name=${lib.escapeURL "Luna NAS"}"
    ];
  };

  # Not needed for NFSv4.
  services.rpcbind.enable = lib.mkForce false;
}
