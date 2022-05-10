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
    timeServers = [
      "1.europe.pool.ntp.org"
      "1.lt.pool.ntp.org"
      "2.europe.pool.ntp.org"
    ];
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

  users = {
    mutableUsers = false;

    users = {
      # Change initialHashedPassword using
      # `nix run nixpkgs#mkpasswd -- -m SHA-512 -s`
      root.initialHashedPassword = "$6$41X.hRL2a8O$Yiz0oCQxrkS1rNUuv09i2IThiPQy0n11s7HpLLyuWscyjNrw3wXtfzf5dQySkXHerHNeCiKtGZ0sTlnF5X9fP.";
      gediminas = {
        isNormalUser = true;
        initialHashedPassword = "$6$9.t9uWJcX9ZlGQ$An53hxQ6YL2JXnjLyEC5euqkyhNF5CsTF6h09gWf2TWFZoYKVuFe3S/c2l3rOjP0fW4mWJGnbxdTQI1Slt4Tg.";
        extraGroups = [ "wheel" ];
        shell = pkgs.fish;
      };
    };
  };
}
