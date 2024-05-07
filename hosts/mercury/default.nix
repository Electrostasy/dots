{ config, pkgs, lib, ... }:

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
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  services.xserver.videoDrivers = [ "nvidia" ];

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "nvidia-x11"
    "nvidia-settings"
    "nvidia-persistenced"
  ];

  hardware = {
    enableRedistributableFirmware = true;
    bluetooth.powerOnBoot = false;
    sensor.iio.enable = true; # orientation detection for auto-rotate.

    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };

    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.stable;

      modesetting.enable = true;
      nvidiaSettings = false;
      powerManagement = {
        enable = true;
        finegrained = true;
      };

      prime = {
        intelBusId = "PCI:0:0:2";
        nvidiaBusId = "PCI:0:1:0";

        offload = {
          enable = true;
          enableOffloadCmd = true; # adds `nvidia-offload` script.
        };
      };
    };
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = [ "kvm-intel" ];
    kernelParams = [
      # Disable memory mapped PCI configuration registers, without this every
      # reboot and shutdown will be stalled or crash (often with null pointer
      # dereferences); with this we can shutdown and reboot fast again.
      "pci=nommconf"
    ];

    initrd = {
      systemd.enable = true;

      luks.devices."cryptroot".device = "/dev/disk/by-uuid/eea26205-2ae5-4d2c-9a13-32c7d9ae2421";

      # Panel orientation detection does not work (is it even supported?), and
      # hardware keyboard's state is not detected (folded and inactive/unfolded
      # and active).
      unl0kr = {
        enable = true;
        settings.general.animations = true;
      };

      availableKernelModules = [
        "nvme"
        "usbhid"
        "xhci_pci"

        # Required for unl0kr.
        "evdev"

        # Required for touchscreen support.
        "hid_multitouch"
        "i2c_hid_acpi"
        "intel_lpss_pci"
      ];
    };

    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };

    tmp = {
      useTmpfs = true;
      tmpfsSize = "75%";
    };
  };

  environment.persistence.state = {
    enable = true;

    users.electro = {
      files = [ ".config/git-credential-keepassxc" ];

      directories = [
        "Documents"
        "Downloads"
        "Pictures"
      ];
    };
  };

  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = [
        "defaults"
        "size=1G"
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

  swapDevices = [{
    device = "${config.environment.persistence.state.persistentStoragePath}/swapfile";
    size = 4 * 1024;
  }];

  # Can only use one of these.
  services.power-profiles-daemon.enable = false;
  services.tlp.enable = true;

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

  networking = {
    dhcpcd.enable = false;
    useDHCP = false;
    useNetworkd = true;

    networkmanager = {
      # With the iwd backend, autoconnect does not work, even if we set
      # `wifi.iwd.autoconnect = false`. As networks are managed with NetworkManager,
      # iwd is not aware of them without converting them to iwd's format, but not
      # using iwd's autoconnect functionality is not working either.
      wifi.backend = "wpa_supplicant";

      dns = "systemd-resolved";

      ensureProfiles = {
        environmentFiles = [ config.sops.secrets.networkmanager.path ];
        profiles = {
          home-wifi = {
            ipv4.method = "auto";
            connection = {
              id = "Sukceno";
              type = "wifi";
              autoconnect = true;
            };
            wifi.ssid = "Sukceno";
            wifi-security = {
              auth-alg = "open";
              key-mgmt = "wpa-psk";
              psk = "$PSK_SUKCENO";
            };
          };

          home-wifi-fast = {
            ipv4.method = "auto";
            connection = {
              id = "Sukceno5G";
              type = "wifi";
              autoconnect = true;
            };
            wifi.ssid = "Sukceno5G";
            wifi-security = {
              auth-alg = "open";
              key-mgmt = "wpa-psk";
              psk = "$PSK_SUKCENO5G";
            };
          };

          work-3 = {
            ipv4.method = "auto";
            connection = {
              id = "L19A3A";
              type = "wifi";
              autoconnect = true;
            };
            wifi.ssid = "L19A3A";
            wifi-security = {
              auth-alg = "open";
              key-mgmt = "wpa-psk";
              psk = "$PSK_L19A3A";
            };
          };

          work-4 = {
            ipv4.method = "auto";
            connection = {
              id = "L19A";
              type = "wifi";
              autoconnect = true;
            };
            wifi.ssid = "L19A";
            wifi-security = {
              auth-alg = "open";
              key-mgmt = "wpa-psk";
              psk = "$PSK_L19A";
            };
          };
        };
      };
    };
  };

  systemd.network = {
    enable = true;
    wait-online.timeout = 0;

    networks = {
      "40-wireless" = {
        name = "wl*";

        DHCP = "yes";
        dns = [ "9.9.9.9" ];

        networkConfig = {
          IgnoreCarrierLoss = "yes";
          LinkLocalAddressing = "no";
        };

        dhcpV4Config = {
          Anonymize = true;
          RouteMetric = 20;
        };
      };

      "40-tethered" = {
        name = "enp*";

        DHCP = "yes";
        dns = [ "9.9.9.9" ];

        networkConfig = {
          IgnoreCarrierLoss = "yes";
          LinkLocalAddressing = "no";
        };

        dhcpV4Config.RouteMetric = 30;
      };
    };
  };

  users = {
    mutableUsers = false;
    users.electro = {
      isNormalUser = true;
      hashedPasswordFile = config.sops.secrets.electroPassword.path;
      extraGroups = [
        "wheel" # allow using `sudo` for this user.
        "networkmanager" # don't ask password when connecting to networks.
      ];
      uid = 1000;
      openssh.authorizedKeys.keyFiles = [ ../terra/ssh_host_ed25519_key.pub ];
    };
  };

  system.stateVersion = "24.05";
}
