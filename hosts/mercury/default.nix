{ config, pkgs, ... }:

{
  imports = [
    ../../profiles/firefox.nix
    ../../profiles/fonts.nix
    ../../profiles/gnome.nix
    ../../profiles/mpv.nix
    ../../profiles/mullvad
    ../../profiles/neovim
    ../../profiles/shell
    ../../profiles/ssh
    ../../profiles/tailscale.nix
    ../luna/nfs-share.nix
  ];

  nixpkgs = {
    hostPlatform.system = "x86_64-linux";
    allowUnfreePackages = [ "nvidia-x11" ];
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;

    secrets = {
      networkmanager = {};
      electroPassword.neededForUsers = true;
      electroIdentity = {
        mode = "0400";
        owner = config.users.users.electro.name;
      };
    };
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware = {
    enableRedistributableFirmware = true;
    bluetooth.powerOnBoot = false;
    sensor.iio.enable = true; # orientation detection for auto-rotate.

    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.beta;

      open = true;
      nvidiaSettings = false;

      powerManagement = {
        enable = true;
        finegrained = true;
      };

      prime = {
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";

        offload = {
          enable = true;
          enableOffloadCmd = true; # adds `nvidia-offload` script.
        };
      };
    };
  };

  boot = {
    initrd = {
      luks.devices."cryptroot" = {
        device = "/dev/disk/by-uuid/eea26205-2ae5-4d2c-9a13-32c7d9ae2421";
        allowDiscards = true;
        bypassWorkqueues = true;
      };

      restore-root = {
        enable = true;

        device = "/dev/mapper/cryptroot";
      };

      availableKernelModules = [
        "nvme"
        "usbhid"
        "xhci_pci"
      ];
    };

    kernelPackages = pkgs.linuxPackages_latest;

    # If hid_asus takes control of the touchpad, no touchpad features besides
    # pointing will work (and it will not be very good), unless it is bound to
    # hid_multitouch first.
    extraModprobeConfig = ''
      softdep hid_asus pre: hid_multitouch
    '';

    kernelParams = [
      # Enable deep sleep/s2ram (suspend to RAM) due to much better battery life
      # on this device than s2idle (suspend to idle).
      "mem_sleep_default=deep"
    ];

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

  fileSystems = {
    # Ensure time out appears when the actual physical device fails to appear,
    # otherwise, systemd cannot set the infinite timeout (such as when using
    # /dev/disk/by-* symlinks) for entering the passphrase:
    # https://github.com/NixOS/nixpkgs/issues/250003#issuecomment-1724708072
    "/" = {
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
      device = "/dev/disk/by-label/boot";
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
  };

  swapDevices = [
    { device = "/dev/disk/by-partuuid/19569fdc-0dc6-4fd7-aef0-ec770aaf1f6a"; randomEncryption.enable = true; }
  ];

  preservation.enable = true;

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

  networking.networkmanager.ensureProfiles = {
    environmentFiles = [ config.sops.secrets.networkmanager.path ];

    profiles = {
      home-wifi = {
        connection = {
          id = "home";
          type = "wifi";
          autoconnect = true;
        };

        wifi.ssid = "$SSID_HOME_WIFI";
        wifi-security = {
          key-mgmt = "wpa-psk";
          psk = "$PSK_HOME_WIFI";
        };

        ipv4.method = "auto";
      };

      work-wifi = {
        connection = {
          id = "work";
          type = "wifi";
          autoconnect = true;
        };

        wifi.ssid = "$SSID_WORK_WIFI";
        wifi-security = {
          auth-alg = "open";
          key-mgmt = "wpa-psk";
          psk = "$PSK_WORK_WIFI";
        };

        ipv4.method = "auto";
      };
    };
  };

  systemd.network = {
    networks."40-wireless" = {
      matchConfig.WLANInterfaceType = "station";
      dhcpV4Config.Anonymize = true;
    };

    links."40-wireless-random-mac" = {
      matchConfig.WLANInterfaceType = "station";
      linkConfig.MACAddressPolicy = "random";
    };
  };

  environment.systemPackages = with pkgs; [
    gnomeExtensions.fullscreen-to-empty-workspace-2
    rnote
  ];

  programs.dconf.profiles.user.databases = [{
    settings."org/gnome/shell/extensions/fullscreen-to-empty-workspace".move-window-when-maximized = false;
  }];

  users.users.electro = {
    isNormalUser = true;
    uid = 1000;

    # Change password using:
    # $ nix run nixpkgs#mkpasswd -- -m SHA-512 -s
    hashedPasswordFile = config.sops.secrets.electroPassword.path;

    extraGroups = [
      "wheel" # allow using `sudo` for this user.
    ];

    openssh.authorizedKeys.keyFiles = [
      ../terra/id_ed25519.pub
      ../venus/id_ed25519.pub
    ];
  };

  system.stateVersion = "25.05";
}
