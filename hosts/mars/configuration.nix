{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  system.stateVersion = "21.11";

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_latest;
  };

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
    };
    settings.auto-optimise-store = true;
  };

  time.timeZone = "Europe/Vilnius";

  networking = {
    hostName = "mars";
    timeServers = [
      "1.europe.pool.ntp.org"
      "1.lt.pool.ntp.org"
      "2.europe.pool.ntp.org"
    ];
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
    execWheelOnly = true;
  };

  hardware.sane.enable = true;

  programs.ssh.knownHosts = {
    phobos.publicKeyFile = ../phobos/ssh_root_ed25519_key.pub;
  };

  # Without dconf enabled, GTK settings in Home Manager won't work
  programs.dconf.enable = true;
  services = {
    openssh = {
      enable = true;
      permitRootLogin = "no";
      passwordAuthentication = false;
      kbdInteractiveAuthentication = false;
    };
    dbus = {
      enable = true;
      packages = [ pkgs.dconf ];
    };
    avahi = {
      enable = true;
      publish = {
        enable = true;
        addresses = true;
        domain = true;
      };
      nssmdns = true;
      interfaces = [ "eno1" "enp8s0" ];
    };
  };

  users = {
    mutableUsers = false;
    # Change initialHashedPassword using
    # `nix run nixpkgs#mkpasswd -- -m SHA-512 -s`
    users = {
      root.initialHashedPassword = "$6$XBb5AVQUp0Mx8t.J$NkVlFCGiS8SQWHXbxImTmEBgyPJKgeqyninY18NdJaL3AVh1uCZxV.3ciZy66Pj0CAGWIobkmTp.vOqefVUgW1";
      electro = {
        isNormalUser = true;
        initialHashedPassword = "$6$MvsOwXOO9zUGCIQu$88hXJZkSR3okcpW99Xgcs77FLQAkSbCyArsagoducjN0gTY7goCZ4vN07I2zoTECdz1pHUtIVgJYWlwMnEdoY1";
        extraGroups = [ "wheel" ];
        shell = pkgs.fish;
      };
    };
  };
}
