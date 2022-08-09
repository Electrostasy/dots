{ config, pkgs, persistMount, ... }:

{
  imports = [ ./media.nix ];

  system.stateVersion = "22.05";

  boot = {
    initrd.availableKernelModules = [ "usb_storage" "uas" "usbhid" ];
    kernelPackages = pkgs.linuxPackages_latest;
    tmpOnTmpfs = true;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = [ "defaults" "size=256M" "mode=755" ];
    };

    # NOTE: Raspberry Pi 4 UEFI Firmware is located at
    # `/dev/mmcblk0p1` or `/dev/disk/by-label/firmware`
    "/boot" = {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };

    "/nix" = {
      device = "/dev/disk/by-label/data";
      fsType = "btrfs";
      options = [ "subvol=nix" "noatime" "nodiratime" "compress-force=zstd:3" ];
    };

    "/state" = {
      device = "/dev/disk/by-label/data";
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

  services.avahi.interfaces = [ "enabcm6e4ei0" ];

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

    # Change password in ./secrets.yaml using
    # `nix run nixpkgs#mkpasswd -- -m SHA-512 -s`
    users = {
      root.passwordFile = config.sops.secrets.rootPassword.path;
      pi = {
        isNormalUser = true;
        passwordFile = config.sops.secrets.piPassword.path;
        extraGroups = [ "wheel" ];
        shell = pkgs.fish;
        openssh.authorizedKeys.keyFiles = [
          ../terra/ssh_electro_ed25519_key.pub
          ../mercury/ssh_gediminas_ed25519_key.pub
        ];
      };
    };
  };
}
