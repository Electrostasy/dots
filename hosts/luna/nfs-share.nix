{ lib, ... }:

{
  fileSystems."/mnt/luna" = {
    device = "luna:/";
    fsType = "nfs4";
    options = [
      "noatime"

      # Do not mount automatically at boot, as this can make boot take much longer
      # if the share is unavailable - mount on demand instead.
      "noauto"
      "x-systemd.automount"
      "x-systemd.mount-timeout=10"
      "x-systemd.idle-timeout=10min"
      "_netdev"

      # Default device timeout is 90s, only `nofail` will make boot/shutdown take
      # 90s longer unless we reconfigure the timeout.
      "nofail"
      "x-systemd.device-timeout=5"

      # Set gvfs options for showing up in the file manager with the correct icons
      # and name set.
      "x-gvfs-icon=folder-remote"
      "x-gvfs-name=${lib.escapeURL "Luna NAS"}"
      "x-gvfs-show"
      "x-gvfs-symbolic-icon=folder-remote-symbolic"
    ];
  };

  # Not needed for NFSv4.
  services.rpcbind.enable = lib.mkForce false;
}
