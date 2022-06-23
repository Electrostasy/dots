{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./nfs.nix
  ];

  system.stateVersion = "22.05";

  boot = {
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
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

  documentation.enable = false;

  services.avahi.interfaces = [ "eth0" ];

  sops = {
    defaultSopsFile = ./secrets.yaml;

    secrets = {
      rootPassword.neededForUsers = true;
      piPassword.neededForUsers = true;
      sshHostKey = { };
    };
  };

  services.openssh.hostKeys = [
    { type = "ed25519"; inherit (config.sops.secrets.sshHostKey) path; }
  ];

  users = {
    mutableUsers = false;

    # Change initialHashedPassword using
    # `nix run nixpkgs#mkpasswd -- -m SHA-512 -s`
    users = {
      root.passwordFile = config.sops.secrets.rootPassword.path;
      pi = {
        isNormalUser = true;
        group = "pi";
        extraGroups = [ "wheel" ];
        passwordFile = config.sops.secrets.piPassword.path;
        openssh.authorizedKeys.keyFiles = [
          ../mars/ssh_electro_ed25519_key.pub
        ];
      };
    };
  };
}
