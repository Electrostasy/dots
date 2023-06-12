{ config, pkgs, ... }:

{
  nixpkgs.hostPlatform = "aarch64-linux";

  system.stateVersion = "23.05";

  boot = {
    tmp.useTmpfs = true;
    kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;
    loader = {
      generic-extlinux-compatible.enable = false;
      systemd-boot.enable = true;
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

    "/boot/firmware" = {
      device = "/dev/disk/by-label/TOW-BOOT-FI";
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

  # Raspberry Pi 4 does not have a RTC and timesyncd is fighting with resolved
  # due to DNSSEC and expired signatures, so for now just synchronize time
  # with local network router ("DNSSEC validation failed: signature-expired").
  services.timesyncd.servers = lib.mkForce [ "192.168.205.1" ];

  environment.systemPackages = with pkgs; [
    libgpiod
    libraspberrypi
    vim
  ];

  # 3D Printer web interface & firmware.
  services.moonraker = {
    enable = true;
    settings = {
      authorization = {
        force_logins = true;
        cors_domains = [
          "*.local"
          "*.lan"
          "*://my.mainsail.xyz"
        ];
        trusted_clients = [
          "10.0.0.0/8"
          "127.0.0.0/8"
        ];
      };
    };
  };
  services.mainsail.enable = true;
  services.klipper = {
    enable = true;

    user = "klipper";
    group = "klipper";

    firmwares.einsy = {
      enable = true;
      serial = "/dev/ttyACM0";
      configFile = ./einsy.config;
    };

    # firmwares.rp2040 = {
    #   enable = true;
    #   serial = "/dev/null"; # flashed over USB.
    #   configFile = ./rp2040.config;
    # };

    configFile = ./printer-prusa-mk3s.cfg;
  };

  networking = {
    hostName = "phobos";

    dhcpcd.enable = false;
    useDHCP = false;
    firewall.allowedTCPPorts = [ 80 ];
    firewall.allowedUDPPorts = [ 80 ];
  };

  systemd.network = {
    enable = true;

    networks."40-wired" = {
      name = "en*";

      DHCP = "yes";
      dns = [ "9.9.9.9" ];
    };
  };

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

    groups.klipper = { };
    users.klipper = {
      isSystemUser = true;
      group = "klipper";
    };

    users.moonraker.extraGroups = [ "klipper" ];
  };
}
