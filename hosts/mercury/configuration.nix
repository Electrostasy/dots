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

  services.avahi.interfaces = [ "enp0s25" ];

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
