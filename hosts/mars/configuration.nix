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
    autoOptimiseStore = true;
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

  services = {
    openssh = {
      enable = true;
      permitRootLogin = "no";
      passwordAuthentication = false;
    };

    pipewire = {
      enable = true;
      pulse.enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      media-session.enable = true;
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
    ];
  };

  users = {
    groups.electro = {};

    mutableUsers = false;
    # Change initialHashedPassword using
    # `nix run nixpkgs#mkpasswd -- -m SHA-512 -s`
    users.root.initialHashedPassword = "$6$41X.hRL2a8O$Yiz0oCQxrkS1rNUuv09i2IThiPQy0n11s7HpLLyuWscyjNrw3wXtfzf5dQySkXHerHNeCiKtGZ0sTlnF5X9fP.";
    users.electro = {
      isNormalUser = true;
      group = "electro";
      initialHashedPassword = "$6$9.t9uWJcX9ZlGQ$An53hxQ6YL2JXnjLyEC5euqkyhNF5CsTF6h09gWf2TWFZoYKVuFe3S/c2l3rOjP0fW4mWJGnbxdTQI1Slt4Tg.";
      extraGroups = [ "wheel" "video" "audio" "sound" ];
      shell = pkgs.fish;
    };
  };

  # Stateful directories
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

  fileSystems."/home/electro/.cache" = {
    device = "/nix/state/home/electro/.cache";
    fsType = "none";
    options = [ "bind" ];
  };

  fileSystems."/home/electro/.mozilla" = {
    device = "/nix/state/home/electro/.mozilla";
    fsType = "none";
    options = [ "bind" ];
  };

  fileSystems."/home/electro/.ssh" = {
    device = "/nix/state/home/electro/.ssh";
    fsType = "none";
    options = [ "bind" ];
  };

  fileSystems."/home/electro/Pictures" = {
    device = "/nix/state/home/electro/Pictures";
    fsType = "none";
    options = [ "bind" ];
  };
}
