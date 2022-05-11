{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  system.stateVersion = "21.11";

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  time.timeZone = "Europe/Vilnius";

  networking = {
    hostName = "mercury";

    wireless = {
      enable = true;
      userControlled.enable = true;
    };

    dhcpcd.enable = false;
    useDHCP = false;
    useNetworkd = true;
  };

  # Keeps failing, but networking works fine without it
  systemd.services."systemd-networkd-wait-online".enable = false;
  systemd.network = {
    enable = true;

    # Wired network configuration to be used at work and at home, depending
    # on where a connection can be established
    networks."40-wired-work-or-home" = {
      name = "enp0s25";

      address = [
        "192.168.200.26" # Try work IP
        "192.168.205.56" # Fallback to home IP
      ];
      gateway = [
        "192.168.200.1" # Try work gateway
        "192.168.205.1" # Fallback to home gateway
      ];
      dns = [
        "192.168.200.10" # Try work DNS
        "127.0.0.1" "::1" # Fallback to local DNS resolver
      ];
      ntp = [
        "1.europe.pool.ntp.org"
        "1.lt.pool.ntp.org"
        "2.europe.pool.ntp.org"
      ];

      dhcpV4Config.RouteMetric = 1024;
    };

    # Wireless network configuration to be used wherever, taking public
    # networks into accouont
    networks."40-wireless" = {
      name = "wlp3s0";

      DHCP = "yes";
      dns = [ "127.0.0.1" "::1" ];
      ntp = [
        "1.europe.pool.ntp.org"
        "1.lt.pool.ntp.org"
        "2.europe.pool.ntp.org"
      ];

      networkConfig.IgnoreCarrierLoss = "yes";
      dhcpV4Config = {
        Anonymize = true;
        RouteMetric = 2048;
      };
    };

    # Randomize the wireless interface MAC Address each time the device appears
    links."40-wireless-random-mac" = {
      matchConfig.Type = "wlan";
      linkConfig.MACAddressPolicy = "random";
    };
  };

  services = {
    avahi.interfaces = [ "enp0s25" ];

    samba = {
      enable = true;
      openFirewall = true;

      extraConfig = ''
        map to guest = bad user
        load printers = no
        printcap name = /dev/null

        # Limit samba to lan interface
        interfaces = enp0s25 lo
        bind interfaces only = yes

        log file = /var/log/samba/client.%I
        log level = 2
      '';

      shares."Visiems" = {
        path = "/mnt/Visiems";
        browseable = true;
        writable = true;
        public = true;

        # Allow everyone to add/remove/modify files/directories
        "guest ok" = "yes";
        "force user" = "nobody";
        "force group" = "nogroup";

        # Default permissions for files/directories
        "create mask" = 0666;
        "directory mask" = 0777;
      };
    };
  };

  programs.ssh.knownHosts = {
    phobos.publicKeyFile = ../phobos/ssh_root_ed25519_key.pub;
    mars.publicKeyFile = ../mars/ssh_root_ed25519_key.pub;
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;

    secrets = {
      rootPassword.neededForUsers = true;
      gediminasPassword.neededForUsers = true;
    };
  };

  services.openssh.hostKeys = [
    { type = "ed25519"; inherit (config.sops.secrets.sshHostKey) path; }
  ];

  users = {
    mutableUsers = false;

    users = {
      # Change initialHashedPassword using
      # `nix run nixpkgs#mkpasswd -- -m SHA-512 -s`
      root.passwordFile = config.sops.secrets.rootPassword.path;
      gediminas = {
        isNormalUser = true;
        passwordFile = config.sops.secrets.gediminasPassword.path;
        extraGroups = [ "wheel" ];
        shell = pkgs.fish;
      };
    };
  };
}
