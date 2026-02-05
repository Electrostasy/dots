{ config, pkgs, lib, flake, ... }:

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

  sops.secrets.networkmanager = { };

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

    swraid = {
      enable = true;

      mdadmConf = ''
        PROGRAM ${lib.getExe pkgs.mdadm-notify}
      '';
    };

    binfmt.emulatedSystems = [ "aarch64-linux" ];
  };

  hardware = {
    cpu.amd.updateMicrocode = true;
    enableRedistributableFirmware = true;

    # Required for brightness-control-using-ddcutil GNOME extension.
    i2c.enable = true;
  };

  # TODO: TAG+="uaccess" udev rules do not work with
  # brightness-control-using-ddcutil GNOME extension for some reason.
  users.users.electro.extraGroups = [ "i2c" ];

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

    # for disk in /dev/sd[a-d]; do sgdisk $disk -n 1:0:0 -t 1:fd00; done
    # mdadm --create /dev/md/pool --name=pool --level=10 --layout=n2 --raid-devices=4 /dev/sd[a-d]1
    "/data/pool" = {
      device = "/dev/md/pool";
      fsType = "xfs";
      options = [ "noatime" ];
    };
  };

  preservation.enable = true;

  services.smartd = {
    enable = true;

    defaults =
      let
        smartd-notify = pkgs.writeShellScript "smartd-notify" ''
          ${lib.getExe pkgs.notify-send-all} -a 'smartd' -i 'drive-harddisk' -c 'device' \
            "$SMARTD_MESSAGE" "$SMARTD_FULLMESSAGE" &> /dev/null
        '';
      in
      {
        # Schedule a short self-test every morning at 06:00, a long self-test every
        # Saturday at midnight, and send a notification if something goes wrong.
        monitored = "-a -n standby -s (S/../.././06|L/../../6/00) -m <nomailer> -M exec ${smartd-notify}";
        autodetected = "-a -m <nomailer> -M exec ${smartd-notify}";
      };

    devices = [
      { device = "/dev/disk/by-path/pci-0000:02:00.0-nvme-1"; }
      { device = "/dev/disk/by-path/pci-0000:14:00.0-ata-1.0"; }
      { device = "/dev/disk/by-path/pci-0000:14:00.0-ata-2.0"; }
      { device = "/dev/disk/by-path/pci-0000:14:00.0-ata-3.0"; }
      { device = "/dev/disk/by-path/pci-0000:14:00.0-ata-4.0"; }
    ];
  };

  networking = {
    networkmanager = {
      enable = true;

      ensureProfiles = {
        environmentFiles = [ config.sops.secrets.networkmanager.path ];

        profiles = {
          lan = {
            connection = {
              id = "lan";
              type = "ethernet";
              llmnr = 1; # "resolve".
              mdns = 2; # "yes".
            };

            ipv4 = {
              method = "manual";
              addresses = "192.168.100.113/24";
              gateway = "192.168.100.1";
              dns = "192.168.100.10";
            };
          };

          wifi-public = {
            connection = {
              id = "public";
              type = "wifi";
              autoconnect = false;
            };

            wifi.ssid = "$SSID_PUBLIC_WIFI";
            wifi-security = {
              key-mgmt = "wpa-psk";
              psk = "$PSK_PUBLIC_WIFI";
            };
          };

          wifi-ap = {
            connection = {
              id = "ap";
              type = "wifi";
              mdns = 2; # "yes".
              autoconnect = false;
            };

            wifi.ssid = "$SSID_AP_WIFI";
            wifi-security = {
              key-mgmt = "wpa-psk";
              psk = "$PSK_AP_WIFI";
            };
          };
        };
      };
    };

    firewall.allowedUDPPorts = [
      5355 # Link-Local Multicast Name Resolution (LLMNR).
      5353 # Multicast DNS (mDNS).
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
    smartmontools # `smartctl`.
    sqlitebrowser
    stegseek
    testdisk # `fidentify`, `testdisk`, `photorec`, `testdisk`.
    tio
    unixtools.xxd
    untrunc-anthwlock # `untrunc`.
    xlsx2csv
    xq-xml # `xq`.
    zet

    gnomeExtensions.brightness-control-using-ddcutil
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

  programs.dconf.profiles.user.databases = [{
    settings = with lib.gvariant; {
      "org/gnome/shell/extensions/tilingshell".selected-layouts = [ [ "50% Vertical Split" "50% Horizontal Split" ] ];

      # Turn displays off after 10 minutes of inactivity, and lock the
      # session after 30 minutes of inactivity.
      "org/gnome/desktop/session".idle-delay = mkUint32 (10 * 60);
      "org/gnome/desktop/screensaver".lock-delay = mkUint32 (30 * 60);

      "org/gnome/shell/extensions/display-brightness-ddcutil" = {
        button-location = mkInt32 1;
        hide-system-indicator = true;
        show-all-slider = true;
        show-sliders-in-submenu = true;
        show-display-name = false;

        # The extension will not work nor load the above settings correctly
        # unless these keys are present.
        ddcutil-binary-path = lib.getExe pkgs.ddcutil;
        ddcutil-queue-ms = mkDouble 130.0;
        ddcutil-sleep-multiplier = mkDouble 40.0;
      };
    };
  }];

  system.stateVersion = "26.05";
}
