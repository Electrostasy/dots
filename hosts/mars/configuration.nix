{ config, pkgs, persistMount, ... }:

{
  system.stateVersion = "22.05";

  boot = {
    initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "sd_mod" ];
    kernelModules = [ "kvm-intel" ];
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  hardware = {
    cpu.intel.updateMicrocode = true;
    enableRedistributableFirmware = true;
    sane.enable = true;
  };

  zramSwap = {
    enable = true;
    memoryPercent = 50;
    algorithm = "zstd";
  };

  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = [ "defaults" "size=512M" "mode=755" ];
    };

    "/boot" = {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };

    "/nix" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "btrfs";
      options = [ "subvol=nix" "noatime" "nodiratime" "compress=zstd" "ssd" ];
    };

    "/state" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "btrfs";
      options = [ "subvol=state" "noatime" "nodiratime" "compress=zstd" "ssd" ];
      neededForBoot = true;
    };
  };

  environment.persistence.${persistMount} = {
    directories = [ "/etc/nixos" "/etc/ssh" "/var/log" ];
    files = [ "/etc/machine-id" ];
    users.electro.directories = [
      ".cache"
      ".config/Element"
      { directory = ".ssh"; mode = "0700"; }
      ".mozilla"
      "Pictures"
    ];
  };

  time.timeZone = "Europe/Vilnius";
  networking = {
    hostName = "mars";

    dhcpcd.enable = false;
    useDHCP = false;
    useNetworkd = true;
  };

  # Keeps failing, but networking works fine without it
  systemd.services."systemd-networkd-wait-online".enable = false;
  systemd.network = {
    enable = true;

    networks."40-wired" = {
      name = "enp5s0";

      address = [ "192.168.205.23" ];
      gateway = [ "192.168.205.1" ];
      dns = [ "127.0.0.1" "::1" ];
      ntp = [
        "1.europe.pool.ntp.org"
        "1.lt.pool.ntp.org"
        "2.europe.pool.ntp.org"
      ];
    };
  };

  xdg.portal.wlr = {
    enable = true;
    settings.screencast = {
      max_fps = 30;
      chooser_type = "simple";
      chooser_cmd = "${pkgs.slurp}/bin/slurp -f %o -or";
    };
  };

  services.avahi.interfaces = [ "enp0s31f6" "enp5s0" ];

  programs.ssh.knownHosts = {
    phobos.publicKeyFile = ../phobos/ssh_root_ed25519_key.pub;
    mercury.publicKeyFile = ../mercury/ssh_root_ed25519_key.pub;
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;

    secrets = {
      rootPassword.neededForUsers = true;
      electroPassword.neededForUsers = true;
      sshHostKey = { };
    };
  };

  services.openssh.hostKeys = [
    { inherit (config.sops.secrets.sshHostKey) path; type = "ed25519"; }
  ];

  users = {
    mutableUsers = false;

    users = {
      # Change initialHashedPassword using
      # `nix run nixpkgs#mkpasswd -- -m SHA-512 -s`
      root.passwordFile = config.sops.secrets.rootPassword.path;
      electro = {
        isNormalUser = true;
        passwordFile = config.sops.secrets.electroPassword.path;
        extraGroups = [ "wheel" ];
        shell = pkgs.fish;
      };
    };
  };
}
