{ config, pkgs, ... }:

{
  system.stateVersion = "21.11";

  boot = {
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
      raspberryPi = {
        enable = true;
        version = 4;
      };
    };
    kernelPackages = pkgs.linuxPackages_rpi4;
    kernelParams = [
      "8250.nr_uarts=1"
      "console=ttyAMA0,115200"
      "console=tty1"
      "cma=128M"
    ];
  };

  time.timeZone = "Europe/Vilnius";

  networking = {
    hostName = "phobos";
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
  };

  services = {
    openssh = {
      enable = true;
      permitRootLogin = "no";
      passwordAuthentication = false;
    };
  };

  users = {
    mutableUsers = false;

    groups.pi = {};
    # Change initialHashedPassword using
    # `nix run nixpkgs#mkpasswd -- -m SHA-512 -s`
    users.root.initialHashedPassword = "$6$lunt/24c3rtjL/ir$phf/p57IPZVyh7Y6AlGqnGNnhePfUmVmfPn4apEtjMkNqmN0zAOlzrvGHwLlSJdQz6OpHIAbqo3/IRCTjqwlJ0";
    users.pi = {
      isNormalUser = true;
      group = "pi";
      initialHashedPassword = "$6$PmEPeRECuQiC/1XI$6nF0ymwceDeQq8YvPOnos0xY5Q9fDun1zgbIqIyg4yalb6/HBYgS7c2M1JXb8rIT3gfZElqZIrFv.Sla1qM1q1";
      extraGroups = [ "wheel" ];
    };
  };
}
