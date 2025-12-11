{ config, pkgs, flake, ... }:

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
    initrd = {
      luks.devices."cryptroot" = {
        device = "/dev/disk/by-partuuid/6e31b86f-1d1d-4cd8-91b3-79af16dda198";
        allowDiscards = true;
        bypassWorkqueues = true;
      };

      restore-root = {
        enable = true;

        device = "/dev/mapper/cryptroot";
      };

      availableKernelModules = [
        # TODO
        # "xhci_pci"
        # "ahci"
        # "nvme"
        # "usbhid"
        # "sd_mod"
      ];
    };

    # TODO: emulate usb drive?
    # https://gist.github.com/drygdryg/26795b9e454e08659248c8ef20e9be45
    # https://unix.stackexchange.com/questions/373569/emulating-usb-device-with-a-file-using-g-mass-storage-udc-core-couldnt-find
    kernelPackages = pkgs.linuxPackages_latest;

    loader = {
      systemd-boot = {
        enable = true;
        consoleMode = "max";
      };

      efi.canTouchEfiVariables = true;
      timeout = 0; # show menu only while holding down a button.
    };

    binfmt.emulatedSystems = [ "aarch64-linux" ];
  };

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.open = true;

  power.ups = {
    enable = true;

    mode = "standalone";

    ups."UPS-1" = {
      description = "APC ..."; # TODO
      driver = "usbhid-ups"; # driver name from https://networkupstools.org/stable-hcl.html
      port = "auto"; # usbhid-ups driver always use value "auto"
      directives = [
        # TODO
        # https://wiki.nixos.org/wiki/Uninterruptible_power_supply
      ];
    };
  };

  hardware = {
    cpu.amd.updateMicrocode = true;
    enableRedistributableFirmware = true;
  };

  fileSystems = {
    "/" = {
      # Ensure time out appears when the actual physical device fails to appear,
      # otherwise, systemd cannot set the infinite timeout (such as when using
      # /dev/disk/by-* symlinks) for entering the passphrase:
      # https://github.com/NixOS/nixpkgs/issues/250003#issuecomment-1724708072
      device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [
        "subvol=root"
        "noatime"
        "compress-force=zstd:1"
        "discard=async"
      ];
    };

    "/boot" = {
      device = "/dev/disk/by-label/BOOT";
      fsType = "vfat";
      options = [ "umask=0077" ];
    };

    "/nix" = {
      device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [
        "subvol=nix"
        "noatime"
        "compress-force=zstd:1"
        "discard=async"
      ];
    };

    "/persist" = {
      device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [
        "subvol=persist"
        "noatime"
        "compress-force=zstd:1"
        "discard=async"
      ];
      neededForBoot = true;
    };

    "/mnt/berla/Visiems" = {
      device = "//berla/Visiems";
      fsType = "cifs";
      options = [
        "x-systemd.automount"
        "noauto"
        "x-systemd.idle-timeout=60"
        "x-systemd.device-timeout=5s"
        "x-systemd.mount-timeout=5s"
        "credentials=${config.sops.secrets.cifsCredentials}"
      ];
    };

    "/mnt/server/Visiems" = {
      device = "//server/Visiems";
      fsType = "cifs";
      options = [
        "x-systemd.automount"
        "noauto"
        "x-systemd.idle-timeout=60"
        "x-systemd.device-timeout=5s"
        "x-systemd.mount-timeout=5s"
        "credentials=${config.sops.secrets.cifsCredentials}"
      ];
    };
  };

  preservation.enable = true;

  networking.useDHCP = false;
  systemd.network.networks."20-work" = {
    name = "enp0s25"; # TODO

    address = [ "192.168.200.26" ]; # TODO
    gateway = [ "192.168.200.1" ]; # TODO
    dns = [ "192.168.200.10" ]; # TODO
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
    hashcat
    imagemagick
    john
    libewf
    mkvtoolnix-cli # `mkvextract`, `mkvinfo`, `mkvmerge`, `mkvpropedit`.
    qpdf
    repgrep
    ripgrep
    sleuthkit # `mmls`, `fls`, `fsstat`, `icat`, ...
    sqlitebrowser
    stegseek
    testdisk # `fidentify`, `testdisk`.`, `photorec`, `testdisk`.
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

  users.users.electro = {
    isNormalUser = true;
    uid = 1000;

    # Change password using:
    # $ nix run nixpkgs#mkpasswd -- -m SHA-512 -s
    hashedPasswordFile = config.sops.secrets.electroPassword.path;

    extraGroups = [
      "libvirtd"
      "wheel"
    ];

    openssh.authorizedKeys.keyFiles = [
      ../mercury/id_ed25519.pub
      ../terra/id_ed25519.pub
      ../venus/id_ed25519.pub
    ];
  };

  system.stateVersion = "26.05";
}
