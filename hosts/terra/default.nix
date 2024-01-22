{ config, pkgs, ... }:

{
  imports = [
    ../../profiles/system/common
    ../../profiles/system/firefox
    ../../profiles/system/gnome
    ../../profiles/system/mullvad
    ../../profiles/system/shell
    ../../profiles/system/ssh
    ./audio.nix
    ./gaming.nix
    ./home.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "22.05";

  boot = {
    initrd.availableKernelModules = [
      "xhci_pci"
      "ahci"
      "nvme"
      "usbhid"
      "sd_mod"
    ];
    kernelModules = [ "kvm-intel" ];
    kernelPackages = pkgs.linuxPackages_latest;
    tmp = {
      useTmpfs = true;
      # Use a higher than default (50%) upper limit for /tmp to not run out of
      # space compiling programs.
      tmpfsSize = "75%";
    };

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    binfmt.emulatedSystems = [ "aarch64-linux" ];
  };

  hardware = {
    cpu.intel.updateMicrocode = true;
    enableRedistributableFirmware = true;
  };

  # Tweaks CPU scheduler for responsiveness over throughput.
  programs.cfs-zen-tweaks.enable = true;

  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = [
        "defaults"
        "size=512M"
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
        "compress-force=zstd:1"
        "discard=async"
      ];
    };

    "/state" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "btrfs";
      options = [
        "subvol=state"
        "noatime"
        "compress-force=zstd:1"
        "discard=async"
      ];
      neededForBoot = true;
    };
  };

  environment.persistence."/state" = {
    enable = true;

    users.electro = {
      files = [
        ".config/git-credential-keepassxc"
        ".mozilla/native-messaging-hosts/org.keepassxc.keepassxc_browser.json"
      ];

      directories = [
        ".cache"
        ".config/PrusaSlicer"
        ".config/keepassxc"
        ".local/share/fish"
        ".mozilla/firefox"
        "Documents"
        "Downloads"
        "Pictures"
      ];
    };
  };

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
      name = "enp*";

      DHCP = "yes";
      dns = [ "9.9.9.9" ];
    };
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

    # Change password using:
    # $ nix run nixpkgs#mkpasswd -- -m SHA-512 -s
    users.electro = {
      isNormalUser = true;
      hashedPasswordFile = config.sops.secrets.electroPassword.path;
      extraGroups = [ "wheel" ];
      uid = 1000;
      openssh.authorizedKeys.keyFiles = [
        ../venus/ssh_host_ed25519_key.pub
      ];
    };
  };
}
