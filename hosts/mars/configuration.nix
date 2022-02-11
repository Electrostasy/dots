{ config, pkgs, lib, ... }:

{
  system.stateVersion = "21.11";

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_latest;
  };

  nix = {
    settings.auto-optimise-store = true;
    gc = {
      automatic = true;
      dates = "weekly";
    };
  };

  time.timeZone = "Europe/Vilnius";

  networking = {
    hostName = "mars";
    hosts = {
      "192.168.205.85" = [ "phobos" "pi4" ];
      "192.168.205.84" = [ "deimos" "pi3" ];
    };
    timeServers = [
      "1.europe.pool.ntp.org"
      "1.lt.pool.ntp.org"
      "2.europe.pool.ntp.org"
    ];
  };

  security = {
    sudo = {
      enable = true;
      wheelNeedsPassword = false;
      execWheelOnly = true;
    };

    rtkit.enable = true;
  };

  hardware = {
    opengl = {
      enable = true;
      driSupport = true;
    };

    sane.enable = true;
  };

  programs.ssh.knownHosts = {
    phobos.publicKeyFile = ../phobos/ssh_root_ed25519_key.pub;
  };

  services = {
    openssh = {
      enable = true;
      permitRootLogin = "no";
      passwordAuthentication = false;
      kbdInteractiveAuthentication = false;
    };

    pipewire = {
      enable = true;
      pulse.enable = true;
      alsa.enable = false; # Wait for fix from nixos/staging to get merged
      # The module for media-session is automatically enabled
      # if pipewire is enabled, so explicitly shut it down in favour
      # of wireplumber
      media-session.enable = false;
      wireplumber.enable = true;
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
    ];
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
        extraGroups = [ "wheel" "video" "audio" "sound" ];
        shell = pkgs.fish;
      };
    };
  };

  # NFS (phobos)
  fileSystems."/mnt/media/shows" = {
    device = "phobos:/shows";
    fsType = "nfs";
    options = [ "nfsvers=4.2" ];
  };
  fileSystems."/mnt/media/movies" = {
    device = "phobos:/movies";
    fsType = "nfs";
    options = [ "nfsvers=4.2" ];
  };
  fileSystems."/mnt/media/anime" = {
    device = "phobos:/anime";
    fsType = "nfs";
    options = [ "nfsvers=4.2" ];
  };

  # SSH
  fileSystems."/etc/ssh" = {
    device = "/nix/state/etc/ssh";
    fsType = "none";
    options = [ "bind" ];
  };
  fileSystems."/home/electro/.ssh" = {
    device = "/nix/state/home/electro/.ssh";
    fsType = "none";
    options = [ "bind" ];
  };

  # Nix configuration and logs
  fileSystems."/etc/nixos" = {
    device = "/nix/state/etc/nixos";
    fsType = "none";
    options = [ "bind" ];
  };
  fileSystems."/var/log" = {
    device = "/nix/state/var/log";
    fsType = "none";
    options = [ "bind" ];
  };

  # TLDR and Nix-index caches that should persist
  fileSystems."/home/electro/.cache/tealdeer" = {
    device = "/nix/state/home/electro/.cache/tealdeer";
    fsType = "none";
    options = [ "bind" ];
  };
  fileSystems."/home/electro/.cache/nix-index" = {
    device = "/nix/state/home/electro/.cache/nix-index";
    fsType = "none";
    options = [ "bind" ];
  };

  fileSystems."/home/electro/.mozilla" = {
    device = "/nix/state/home/electro/.mozilla";
    fsType = "none";
    options = [ "bind" ];
  };

  # Wallpapers and stuff
  fileSystems."/home/electro/Pictures" = {
    device = "/nix/state/home/electro/Pictures";
    fsType = "none";
    options = [ "bind" ];
  };
}
