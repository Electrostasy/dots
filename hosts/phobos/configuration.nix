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

    # Change initialHashedPassword using
    # `nix run nixpkgs#mkpasswd -- -m SHA-512 -s`
    users = {
      root.initialHashedPassword = "$6$lunt/24c3rtjL/ir$phf/p57IPZVyh7Y6AlGqnGNnhePfUmVmfPn4apEtjMkNqmN0zAOlzrvGHwLlSJdQz6OpHIAbqo3/IRCTjqwlJ0";
      pi = {
        isNormalUser = true;
        group = "pi";
        extraGroups = [ "wheel" ];
        initialHashedPassword = "$6$PmEPeRECuQiC/1XI$6nF0ymwceDeQq8YvPOnos0xY5Q9fDun1zgbIqIyg4yalb6/HBYgS7c2M1JXb8rIT3gfZElqZIrFv.Sla1qM1q1";
        openssh.authorizedKeys = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC+7jxnKZHlFLnweqGCi1zWGaz9DMDqfb4gI9RL4SV82ZCARR9mAUf6M6bMAlSSYQDwePv+YOinZewgwENCoJMIg3+cD7wMxo9BW6tIzqGIrSCR2rEGUDbforVXhQBoPAEbOOAf0X2jsyB0S6X/fYyOrScLB7RHDUh34DvEY9PuknwglEk5byo18HB12XDoz88PEwKwtWE+SBYnUEEjJF/gIQHBQMvWsccaP6qvCv5dIoqZ5/JQC32LVuEbUmDx6yi8XZBcW7ol8k3gUcjzmrCtlY7ai3SZ9Lzfe2RLjIr2hxNFvPym3Cn28uaHM4hjEyI4AGD2nQ7ryzRAWYDsdllfrCSk4fWR+QMqOVjk5DSugwEzVdvFokj10OyGnwwQx1MvBOk623hYU+zw4SplQc38xI98xACN58Yfcf6EXw/uBOZKDB/NUAgHNk/P5vLQ2e5+tSo+/0XK48ISaVYOh3M5OnnVJ43YrD2iSM/LSJguzXcKJxxIYEhBOmr/cyAR2Y0= electro@mars"
        ];
      };
    };
  };
}
