{ config, pkgs, lib, flake, ... }:

{
  imports = [
    ../../profiles/firefox.nix
    ../../profiles/fonts.nix
    ../../profiles/gnome.nix
    ../../profiles/mpv.nix
    ../../profiles/neovim
    ../../profiles/shell
    ../../profiles/ssh
    ../../profiles/tailscale.nix
    ../luna/nfs-share.nix
    ./ddcutil.nix
    ./ups.nix
    ./vfio.nix
  ];

  nixpkgs = {
    hostPlatform.system = "x86_64-linux";
    overlays = [
      flake.overlays.libewf-fuse
      flake.overlays.qemu-unshare-fix
      flake.overlays.untrunc-anthwlock
    ];
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

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    kernelPackages = pkgs.linuxPackages_latest;

    initrd = {
      systemd.root = "gpt-auto";
      luks.forceLuksSupportInInitrd = true;
      supportedFilesystems.btrfs = true;

      restoreRoot = {
        enable = true;

        device = "/dev/mapper/root";
      };

      availableKernelModules = [
        "xhci_pci"
        "ahci"
        "nvme"
        "usbhid"
        "sd_mod"
      ];
    };

    # swraid = {
    #   enable = true;
    #
    #   mdadmConf = ''
    #     DEVICE /dev/disk/by-path/pci-0000:14:00.0-ata-[1-4].0-part1
    #     ARRAY pool metadata=1.2 devices=/dev/disk/by-path/pci-0000:14:00.0-ata-*.0-part1
    #     PROGRAM ${pkgs.coreutils}/bin/true
    #   '';
    # };

    binfmt.emulatedSystems = [ "aarch64-linux" ];
  };

  hardware = {
    cpu.amd.updateMicrocode = true;
    enableRedistributableFirmware = true;
  };

  fileSystems = {
    "/nix" = {
      device = "/dev/mapper/root";
      fsType = "btrfs";
      options = [ "subvol=nix" ];
    };

    "/persist" = {
      device = "/dev/mapper/root";
      fsType = "btrfs";
      options = [ "subvol=persist" ];
      neededForBoot = true;
    };

    "/data" = {
      device = "/dev/disk/by-label/data";
      fsType = "xfs";
      options = [ "noatime" ];
    };

    # RAID10 created with the following commands:
    # sgdisk /dev/sda -n 1:0:0 -t 1:fd00
    # sgdisk /dev/sdb -n 1:0:0 -t 1:fd00
    # sgdisk /dev/sdc -n 1:0:0 -t 1:fd00
    # sgdisk /dev/sdd -n 1:0:0 -t 1:fd00
    # mdadm --create /dev/md0 --run --level=10 --layout=n2 --raid-devices=4 /dev/sd[a-d]1
    # "/data/pool" = {
    #   device = "/dev/md/pool";
    #   fsType = "xfs";
    #   options = [ "noatime" ];
    # };
  };

  preservation.enable = true;

  networking = {
    networkmanager = {
      enable = true;

      ensureProfiles.profiles.lan = {
        connection = {
          id = "lan";
          type = "ethernet";
          "connection.mdns" = 2; # "yes";
        };

        ipv4 = {
          method = "manual";
          addresses = "192.168.100.113/24";
          gateway = "192.168.100.1";
          dns = "192.168.100.10";
        };

        ipv6.method = "disabled";
      };
    };

    firewall.allowedUDPPorts = [
      5353 # Multicast DNS.
    ];
  };

  environment.systemPackages = with pkgs; [
    bintools-unwrapped
    binwalk
    chars
    detox
    dos2unix
    evtx # `evtx-dump`.
    exiftool
    fd
    ffmpeg
    fio
    flare-floss # `floss`.
    gimp
    gptfdisk # `gdisk`, `sgdisk`.
    hashcat
    imagemagick
    john
    libewf
    libreoffice-fresh
    mkvtoolnix-cli # `mkvextract`, `mkvinfo`, `mkvmerge`, `mkvpropedit`.
    qpdf
    repgrep
    ripgrep
    sleuthkit # `mmls`, `fls`, `fsstat`, `icat`, ...
    sqlitebrowser
    stegseek
    testdisk # `fidentify`, `testdisk`, `photorec`, `testdisk`.
    unixtools.xxd
    untrunc-anthwlock # `untrunc`.
    xlsx2csv
    xq-xml
    zet
  ];

  services.smartd.enable = true;

  systemd.tmpfiles.settings."10-snapper"."/persist/state/.snapshots"."v".mode = "0770";
  services.snapper = {
    persistentTimer = true;
    filters = "/nix/store";

    configs.state = {
      SUBVOLUME = "/persist/state";
      TIMELINE_CREATE = true;
      TIMELINE_CLEANUP = true;
      TIMELINE_LIMIT_MONTHLY = 0;
      TIMELINE_LIMIT_QUARTERLY = 0;
      TIMELINE_LIMIT_YEARLY = 0;
    };
  };

  programs.dconf.profiles.user.databases = [{
    settings = with lib.gvariant; {
      "org/gnome/shell/extensions/tilingshell".selected-layouts = [ [ "50% Vertical Split" "50% Horizontal Split" ] ];

      # Turn displays off after 10 minutes of inactivity, and lock the
      # session after 30 minutes of inactivity.
      "org/gnome/desktop/session".idle-delay = mkUint32 (10 * 60);
      "org/gnome/desktop/screensaver".lock-delay = mkUint32 (30 * 60);
    };
  }];

  users.users.electro = {
    isNormalUser = true;
    uid = 1000;

    # Change password using:
    # $ nix run nixpkgs#mkpasswd -- -m SHA-512 -s
    hashedPasswordFile = config.sops.secrets.electroPassword.path;

    extraGroups = [ "wheel" ];

    openssh.authorizedKeys.keyFiles = [
      ../mercury/id_ed25519.pub
      ../terra/id_ed25519.pub
      ../venus/id_ed25519.pub
    ];
  };

  system.stateVersion = "26.05";
}
