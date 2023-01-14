{ config, pkgs, ... }:

{
  imports = [
    ./build-machine.nix
    ./audio.nix
    ./gaming.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "22.05";

  boot = {
    initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "sd_mod" ];
    kernelModules = [ "kvm-intel" ];
    kernelPackages = pkgs.linuxPackages_latest;
    tmpOnTmpfs = true;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  hardware = {
    cpu.intel.updateMicrocode = true;
    enableRedistributableFirmware = true;
    sane.enable = true;
    video.hidpi.enable = true;
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
      options = [ "subvol=nix" "noatime" "nodiratime" "compress-force=zstd:1" "discard=async" ];
    };

    "/state" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "btrfs";
      options = [ "subvol=state" "noatime" "nodiratime" "compress-force=zstd:1" "discard=async" ];
      neededForBoot = true;
    };
  };

  environment.persistence."/state" = {
    users.electro = {
      files = [
        ".config/git-credential-keepassxc"
        ".mozilla/native-messaging-hosts/org.keepassxc.keepassxc_browser.json"
      ];

      directories = [
        ".cache"
        ".config/keepassxc"
        "documents"
        "downloads"
        ".local/share/fish"
        ".mozilla/firefox"
        "pictures"
        { directory = ".ssh"; mode = "0700"; }
      ];
    };
  };

  time.timeZone = "Europe/Vilnius";
  networking = {
    hostName = "terra";

    dhcpcd.enable = false;
    useDHCP = false;
    useNetworkd = true;
  };

  systemd.network = {
    enable = true;

    wait-online.timeout = 0;

    networks."40-wired" = {
      name = "enp5s0";

      address = [ "192.168.205.23" ];
      gateway = [ "192.168.205.1" ];
      dns = [ "9.9.9.9" ];
    };
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
        uid = 1000;
        shell = pkgs.fish;
        openssh.authorizedKeys.keyFiles = [
          ../venus/ssh_electro_ed25519_key.pub
        ];
      };
    };
  };
}
