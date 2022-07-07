{ config, pkgs, persistMount, ... }:

{
  imports = [ ./media.nix ];

  system.stateVersion = "22.05";

  boot = {
    initrd.availableKernelModules = [ "xhci_pci" "uas" ];
    kernelParams = [
      "8250.nr_uarts=1"
      "console=ttyAMA0,115200"
      "console=tty1"
      "cma=128M"
    ];
    kernelPackages = pkgs.linuxPackages_rpi4;
    tmpOnTmpfs = true;

    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  swapDevices = [
    { device = "/dev/disk/by-label/swap"; }
  ];

  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = [ "defaults" "size=256M" "mode=755" ];
    };

    "/boot" = {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };

    "/nix" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "btrfs";
      options = [ "subvol=nix" "noatime" "nodiratime" "compress-force=zstd:3" ];
    };

    "/state" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "btrfs";
      options = [ "subvol=state" "noatime" "nodiratime" "compress-force=zstd:3" ];
      neededForBoot = true;
    };
  };

  environment.persistence.${persistMount} = {
    directories = [
      "/etc/nixos"
      "/etc/ssh"
      "/var/log"
    ];
    files = [ "/etc/machine-id" ];
  };

  time.timeZone = "Europe/Vilnius";

  networking.hostName = "phobos";

  services.timesyncd.servers = [
    "1.europe.pool.ntp.org"
    "1.lt.pool.ntp.org"
    "2.europe.pool.ntp.org"
  ];

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
