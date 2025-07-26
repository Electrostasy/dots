{ lib, ... }:

{
  fileSystems."/mnt/luna" = {
    device = "luna:/";
    fsType = "nfs";
    options = [
      # Prevent lockups on timeout/error.
      "bg"
      "noatime"
      "retry=0"
      "soft"
      "timeo=100"

      # Better performance.
      "nconnect=16"

      # Show in the file manager.
      "x-gvfs-icon=folder-remote"
      "x-gvfs-show"
      "x-gvfs-symbolic-icon=folder-remote-symbolic"

      # Don't mount automatically.
      "_netdev"
      "noauto"
      "x-systemd.automount"
      "x-systemd.idle-timeout=10min"
      "x-systemd.mount-timeout=10"

      "noresvport"
      "x-systemd.requires=tailscaled.service"
      "xprtsec=none"
    ];
  };

  services.rpcbind.enable = lib.mkForce false; # unnecessary for NFSv4.
}
