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
    hostName = "mercury";
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

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
    execWheelOnly = true;
  };

  services.openssh = {
    enable = true;
    permitRootLogin = "no";
    passwordAuthentication = false;
    kbdInteractiveAuthentication = false;
  };

  users = {
    mutableUsers = false;
    # Change initialHashedPassword using
    # `nix run nixpkgs#mkpasswd -- -m SHA-512 -s`
    users = {
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
