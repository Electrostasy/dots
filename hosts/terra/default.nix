{ config, pkgs, ... }:

{
  imports = [
    ../../profiles/common
    ../../profiles/firefox
    ../../profiles/gnome
    ../../profiles/mpv
    ../../profiles/mullvad
    ../../profiles/neovim
    ../../profiles/shell
    ../../profiles/ssh
    ./audio.nix
    ./gaming.nix
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

  environment.systemPackages = with pkgs; [
    f3d
    flacon
    freecad
    freerdp
    gimp
    keepassxc
    libreoffice-fresh
    neo
    nurl
    pastel
    picard
    prusa-slicer
    pt-p300bt-labelmaker
    spek
    via
    youtube-dl
  ];

  programs.mpv.settings = {
    border = "yes";
    autofit-smaller = "1920x1080";
    cursor-autohide = "always";
  };

  hardware = {
    cpu.intel.updateMicrocode = true;
    enableRedistributableFirmware = true;
    keyboard.qmk.enable = true;
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

  environment.persistence.state = {
    enable = true;

    users.electro = {
      files = [
        ".config/git-credential-keepassxc"
      ];

      directories = [
        ".config/PrusaSlicer"
        "Documents"
        "Downloads"
        "Pictures"
      ];
    };
  };

  # Set default mount options for mounting through udisksctl/nautilus.
  services.udisks2.settings."mount_options.conf" = {
    "/dev/disk/by-uuid/e208c920-b9e7-42e6-a38a-ef6aacbeb374" = {
      btrfs_defaults = [
        "noatime"
        "compress-force=zstd:3"
      ];
    };
  };

  networking = {
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
        ../mercury/ssh_host_ed25519_key.pub
        ../venus/ssh_host_ed25519_key.pub
      ];
    };
  };
}
