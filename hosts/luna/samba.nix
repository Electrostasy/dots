{
  fileSystems."/srv/smb" = {
    device = "/mnt/array";
    options = [ "bind" ];
  };

  services.resolved.settings.Resolve.MulticastDNS = true;
  systemd.network.networks."40-enable-mdns-on-lan" = {
    matchConfig.Name = "en*";
    networkConfig.MulticastDNS = true;
    linkConfig.Multicast = true;
  };

  networking.firewall.allowedUDPPorts = [
    5353 # Multicast DNS (mDNS).
  ];

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
        "use sendfile" = "yes";
        "min receivefile size" = 16384;
        "strict sync" = "no";

        "server string" = "Samba %v Server on %h";
        "security" = "user";
        "hosts allow" = "192.168.205. 100.64.0. 127.0.0.1 localhost";
        "hosts deny" = "0.0.0.0/0";

        # NOTE: For Windows clients, need to ensure NTLMv2 is allowed in group
        # policy: "Send NTLMv2 responses only" or similar. Otherwise set:
        # "ntlm auth" = "ntlmv1-permitted" # default is "ntlmv2-only".
      };

      "share" = {
        "path" = "/srv/smb";
        "writeable" = "yes";
        "force group" = "+users";
        "valid users" = "electro sukceno @users";
      };
    };
  };

  services.samba-wsdd = {
    enable = true;

    openFirewall = true;
  };
}
