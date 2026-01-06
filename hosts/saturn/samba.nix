{ config, ... }:

{
  sops.secrets.jupiterCifsCredentials = { };

  preservation.preserveAt."/persist/state".files = [
    "/var/lib/samba/private/passdb.tdb"
  ];

  fileSystems = {
    "/srv/smb/pool" = {
      device = "/data/pool";
      options = [ "bind" ];
    };

    "/mnt/jupiter" = {
      device = "//jupiter/pool";
      fsType = "cifs";
      options = [
        # Show in the file manager.
        "x-gvfs-icon=folder-remote"
        "x-gvfs-show"
        "x-gvfs-symbolic-icon=folder-remote-symbolic"

        # Don't mount automatically.
        "_netdev"
        "noauto"
        "x-systemd.automount"
        "x-systemd.idle-timeout=60s"
        "x-systemd.mount-timeout=10"

        "credentials=${config.sops.secrets.jupiterCifsCredentials.path}"
      ];
    };
  };

  services.samba = {
    enable = true;

    openFirewall = true;

    settings = {
      "global" = {
        # Enforce permissions:
        # https://wiki.archlinux.org/title/Samba#Set_and_forcing_permissions
        "create mask" = "0644";
        "directory mask" = "2775";
        "force create mode" = "0644";
        "force directory mode" = "2775";

        # Use encryption if possible:
        # https://wiki.archlinux.org/title/Samba#Use_native_SMB_transport_encryption
        "server smb encrypt" = "desired";

        # Disable printer sharing:
        # https://wiki.archlinux.org/title/Samba#Disable_printer_sharing
        "load printers" = "no";
        "printing" = "bsd";
        "printcap name" = "/dev/null";
        "disable spoolss" = "yes";
        "show add printer wizard" = "no";

        # Performance options:
        # https://wiki.archlinux.org/title/Samba#Improve_throughput
        "deadtime" = 30;
        "use sendfile" = true;
        "min receivefile size" = 16384;

        "server string" = "Samba server on Saturn";
        "security" = "user";
        "hosts allow" = "192.168.100. 192.168.200. 127.0.0.1 localhost";
        "hosts deny" = "0.0.0.0/0";
      };

      "pool" = {
        "path" = "/srv/smb/pool";
        "browseable" = "yes";
        "force group" = "+users";
        "guest ok" = "no";
        "public" = "no";
        "read only" = "no";
        "valid users" = "electro @users";
      };
    };
  };
}
