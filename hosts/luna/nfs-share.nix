{ lib, ... }:

{
  fileSystems."/mnt/luna" = {
    device = "luna:/";
    fsType = "nfs4";
    options = [
      "noatime"
      "noacl"
      "timeo=14"
      "bg"

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

      # Only mount/unmount when Tailscale is running, this ensures we do not
      # try to mount/unmount prematurely.
      "x-systemd.requires=tailscaled.service"

      # Give up immediately if share is unreachable.
      "retry=0"

      # By default NFS uses privileged TCP ports <1024. Use a new non-privileged
      # TCP source port when a network connection is reestablished. This requires
      # the NFS share to be exported with `insecure`.
      "noresvport"

      # Set gvfs options for showing up in the file manager with the correct icons
      # and name set.
      "x-gvfs-show"
      "x-gvfs-icon=folder-remote"
      "x-gvfs-symbolic-icon=folder-remote-symbolic"
      "x-gvfs-name=${lib.escapeURL "Luna NAS"}"
    ];
  };

  # Not needed for NFSv4.
  services.rpcbind.enable = lib.mkForce false;
}
