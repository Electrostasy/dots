{ config, pkgs, ... }:

{
  nixpkgs.hostPlatform = "aarch64-linux";

  system.stateVersion = "23.05";

  boot = {
    initrd.availableKernelModules = [ "usbhid" ];
    kernelPackages = pkgs.linuxPackages_latest;
    tmp.useTmpfs = true;
    loader = {
      systemd-boot.enable = true;
      # EFI variables are read-only with Tow-Boot.
      efi.canTouchEfiVariables = false;
    };
  };

  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = [
        "defaults"
        "size=256M"
        "mode=755"
      ];
    };

    "/boot" = {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };

    "/nix" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "btrfs";
      options = [
        "subvol=nix"
        "noatime"
        "nodiratime"
        "compress-force=zstd:3"
      ];
    };

    "/state" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "btrfs";
      options = [
        "subvol=state"
        "noatime"
        "nodiratime"
        "compress-force=zstd:3"
      ];
      neededForBoot = true;
    };
  };

  time.timeZone = "Europe/Vilnius";

  networking.hostName = "phobos";

  documentation.enable = false;

  sops = {
    defaultSopsFile = ./secrets.yaml;

    secrets = {
      piPassword.neededForUsers = true;
      sshHostKey = { };
    };
  };

  services.openssh.hostKeys = [
    { type = "ed25519"; inherit (config.sops.secrets.sshHostKey) path; }
  ];

  # Required for vendor shell completions.
  programs.fish.enable = true;

  users = {
    mutableUsers = false;
    users.pi = {
      isNormalUser = true;
      passwordFile = config.sops.secrets.piPassword.path;
      extraGroups = [ "wheel" ];
      uid = 1000;
      shell = pkgs.fish;
      openssh.authorizedKeys.keyFiles = [
        ../jupiter/ssh_gediminas_ed25519_key.pub
        ../terra/ssh_electro_ed25519_key.pub
        ../venus/ssh_electro_ed25519_key.pub
      ];
    };
  };
}
