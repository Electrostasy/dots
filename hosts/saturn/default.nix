{ pkgs, lib, flake, ... }:

{
  imports = [
    ../../profiles/firefox.nix
    ../../profiles/fonts.nix
    ../../profiles/gnome.nix
    ../../profiles/mpv.nix
    ../../profiles/neovim
    ../../profiles/shell.nix
    ../../profiles/ssh.nix
    ../../profiles/tailscale.nix
    ../../users/electro
    ../luna/nfs-share.nix
    ./ddcutil.nix
    ./raid.nix
    ./samba.nix
    ./ups.nix
    ./vfio.nix
  ];

  nixpkgs = {
    hostPlatform.system = "x86_64-linux";
    overlays = [
      flake.overlays.libewf-fuse
      flake.overlays.qemu-unshare-fix
    ];
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
  };

  preservation = {
    enable = true;

    preserveAt."/persist/state".users.electro.directories = [ ".thunderbird" ];
  };

  networking = {
    networkmanager = {
      enable = true;

      ensureProfiles.profiles.lan = {
        connection = {
          id = "lan";
          type = "ethernet";

          # mDNS is faster, but cannot help resolve some machines, while LLMNR
          # just works.
          llmnr = 2; # "yes".
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
      5355 # Link-Local Multicast Name Resolution (LLMNR).
    ];
  };

  services.printing = {
    enable = true;

    drivers = [ pkgs.hplip ];
  };

  hardware.printers = {
    ensureDefaultPrinter = "HP_LaserJet_Pro_MFP_4102dw";
    ensurePrinters = [
      {
        name = "HP_LaserJet_Pro_MFP_4102dw";
        description = "HP LaserJet Pro MFP 4102dw";
        model = "HP/hp-laserjet_pro_mfp_4102-ps.ppd.gz";
        deviceUri = "ipp://192.168.100.103/ipp/print";
        ppdOptions = {
          PageSize = "A4";
        };
      }
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
    imagemagick # `magick`.
    libewf
    libreoffice-fresh
    mkvtoolnix-cli # `mkvextract`, `mkvinfo`, `mkvmerge`, `mkvpropedit`.
    openterface-qt
    qpdf
    repgrep # `rgr`.
    ripgrep
    ripgrep-all # `rga`.
    rsync
    sleuthkit # `mmls`, `fls`, `fsstat`, `icat`, ...
    sqlitebrowser
    stegseek
    testdisk # `fidentify`, `testdisk`, `photorec`, `testdisk`.
    tio
    unixtools.xxd
    untrunc-anthwlock # `untrunc`.
    xlsx2csv
    xq-xml # `xq`.
    zet
  ];

  services.udev.packages = [ pkgs.openterface-qt ];

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

  programs.thunderbird.enable = true;

  programs.dconf.profiles.user.databases = [{
    settings = with lib.gvariant; {
      "org/gnome/shell/extensions/tilingshell".selected-layouts = [ [ "50% Vertical Split" "50% Horizontal Split" ] ];

      # Turn displays off after 10 minutes of inactivity, and lock the
      # session after 30 minutes of inactivity.
      "org/gnome/desktop/session".idle-delay = mkUint32 (10 * 60);
      "org/gnome/desktop/screensaver".lock-delay = mkUint32 (30 * 60);
    };
  }];

  system.stateVersion = "26.05";
}
