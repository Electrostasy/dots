{ config, pkgs, lib, ... }:

{
  imports = [
    ../../profiles/minimal
    ../../profiles/ssh
    ./dendrite.nix
    ./fileserver.nix
    ./headscale.nix
  ];

  nixpkgs.hostPlatform = "aarch64-linux";

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "console=ttyS0,115200n8"
      "console=ttyAMA0,115200n8"
      "console=tty0"
    ];

    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };

    "/var/lib/dendrite" = {
      device = "/dev/disk/by-label/pidata";
      fsType = "btrfs";
      options = [
        "subvol=dendrite"
        "noatime"
        "compress-force=zstd:1"
        "discard=async"
      ];
    };

    "/var/lib/postgresql" = {
      device = "/dev/disk/by-label/pidata";
      fsType = "btrfs";
      options = [
        "subvol=postgresql"
        "noatime"
        "compress-force=zstd:1"
        "discard=async"
        "X-mount.owner=${config.users.users.postgres.name}"
        "X-mount.group=${config.users.groups.postgres.name}"
      ];
    };

    "/srv/http/static" = {
      device = "/dev/disk/by-label/pidata";
      fsType = "btrfs";
      options = [
        "subvol=static"
        "noatime"
        "compress-force=zstd:1"
        "discard=async"
        "X-mount.owner=${config.users.users.electro.name}"
        "X-mount.group=${config.users.groups.users.name}"
      ];
    };

    "/var/lib/headscale" = {
      device = "/dev/disk/by-label/pidata";
      fsType = "btrfs";
      options = [
        "subvol=headscale"
        "noatime"
        "compress-force=zstd:1"
        "discard=async"
        "X-mount.owner=${config.users.users.headscale.name}"
        "X-mount.group=${config.users.groups.headscale.name}"
      ];
    };
  };

  # Raspberry Pi 4 does not have a RTC and timesyncd is fighting with resolved
  # due to DNSSEC and expired signatures, so for now just synchronize time
  # with local network router ("DNSSEC validation failed: signature-expired").
  services.timesyncd.servers = lib.mkForce [ "192.168.205.1" ];

  systemd.network.networks."40-wired" = {
    name = "en*";
    DHCP = "yes";
    dns = [ "9.9.9.9" ];
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      electroPassword.neededForUsers = true;
      electroIdentity = {
        mode = "0400";
        owner = config.users.users.electro.name;
      };
    };
  };

  users = {
    mutableUsers = false;
    users.electro = {
      isNormalUser = true;
      hashedPasswordFile = config.sops.secrets.electroPassword.path;
      extraGroups = [ "wheel" ];
      uid = 1000;
      openssh.authorizedKeys.keyFiles = [
        ../mercury/id_ed25519.pub
        ../terra/id_ed25519.pub
        ../venus/id_ed25519.pub
      ];
    };
  };

  system.stateVersion = "24.05";
}
