{ config, pkgs, lib, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/profiles/minimal.nix"
    ../../profiles/ssh
    ./dendrite.nix
    ./fileserver.nix
    ./headscale.nix
  ];

  nixpkgs.hostPlatform = "aarch64-linux";

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

  boot = {
    loader.generic-extlinux-compatible.enable = true;

    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "8250.nr_uarts=1"
      "console=ttyS0,115200"
    ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-label/BOOT";
      fsType = "vfat";
    };
  };

  # Raspberry Pi 4 does not have a RTC and timesyncd is fighting with resolved
  # due to DNSSEC and expired signatures, so for now just synchronize time
  # with local network router ("DNSSEC validation failed: signature-expired").
  services.timesyncd.servers = lib.mkForce [ "192.168.205.1" ];

  systemd.network.networks."40-wired" = {
    name = "en*";
    networkConfig.DHCP = true;
  };

  users.users.electro = {
    isNormalUser = true;
    uid = 1000;

    # Change password using:
    # $ nix run nixpkgs#mkpasswd -- -m SHA-512 -s
    hashedPasswordFile = config.sops.secrets.electroPassword.path;

    extraGroups = [
      "wheel" # allow using `sudo` for this user.
    ];

    openssh.authorizedKeys.keyFiles = [
      ../mercury/id_ed25519.pub
      ../terra/id_ed25519.pub
      ../venus/id_ed25519.pub
    ];
  };

  system.stateVersion = "24.05";
}
