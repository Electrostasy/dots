{
  fileSystems."/srv/smb" = {
    device = "/mnt/array";
    options = [ "bind" ];
  };

  services.samba = {
    enable = true;

    openFirewall = true;

    settings = {
      global = {
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

        "server string" = "Samba server on Luna";
        "security" = "user";
        "hosts allow" = "192.168.205. 100.64.0. 127.0.0.1 localhost";
        "hosts deny" = "0.0.0.0/0";

        # NOTE: For Windows clients, need to ensure NTLMv2 is allowed in group
        # policy: "Send NTLMv2 responses only" or similar. Otherwise set:
        # "ntlm auth" = "ntlmv1-permitted" # default is "ntlmv2-only".
      };

      "share" = {
        "path" = "/srv/smb";
        "comment" = "NAS accessible by electro and sukceno";
        "valid users" = "electro sukceno @users";
        "force group" = "+users";
        "public" = "no";
        "browseable" = "yes";
        "read only" = "no";
        "guest ok" = "no";
      };
    };
  };

  services.samba-wsdd = {
    enable = true;

    openFirewall = true;
  };

  services.avahi = {
    enable = true;

    openFirewall = true;

    publish = {
      enable = true;

      # Automatically register mDNS records (without the need for an `extraServiceFile`).
      userServices = true;
    };

    nssmdns4 = true;
  };
}
