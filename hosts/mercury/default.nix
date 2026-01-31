{ config, pkgs, ... }:

{
  imports = [
    ../../profiles/firefox.nix
    ../../profiles/fonts.nix
    ../../profiles/gnome.nix
    ../../profiles/mpv.nix
    ../../profiles/mullvad
    ../../profiles/neovim
    ../../profiles/shell.nix
    ../../profiles/ssh.nix
    ../../profiles/tailscale.nix
    ../../users/electro
    ../luna/nfs-share.nix
  ];

  nixpkgs = {
    hostPlatform.system = "x86_64-linux";
    config.allowUnfreePackages = [ "nvidia-x11" ];
  };

  sops.secrets.networkmanager = { };

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
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [ "mem_sleep_default=deep" ];

    # If hid_asus takes control of the touchpad, no touchpad features besides
    # pointing will work (and it will not be very good), unless it is bound to
    # hid_multitouch first.
    extraModprobeConfig = ''
      softdep hid_asus pre: hid_multitouch
    '';

    initrd = {
      systemd.root = "gpt-auto";
      luks.forceLuksSupportInInitrd = true;
      supportedFilesystems.btrfs = true;

      restoreRoot = {
        enable = true;

        device = "/dev/mapper/root";
      };

      availableKernelModules = [
        "nvme"
        "usbhid"
        "xhci_pci"
      ];
    };

    binfmt.emulatedSystems = [ "aarch64-linux" ];
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
  };

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

  system.stateVersion = "25.05";
}
