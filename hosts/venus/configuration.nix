{ config, pkgs, ... }:

{
  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "23.11";

  boot = {
    initrd = {
      # Required for Plymouth to show graphical password prompt on boot.
      systemd.enable = true;

      availableKernelModules = [
        "ahci"
        "ehci_pci"
        "sd_mod"
        "sdhci_pci"
        "usb_storage"
        "xhci_pci"
      ];

      luks.devices."cryptroot" = {
        device = "/dev/disk/by-uuid/a408f4d3-eff8-455f-81d3-150b53265f40";
        allowDiscards = true;
      };
    };

    plymouth.enable = true;

    kernelModules = [ "kvm-intel" ];
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "acpi.ec_no_wakeup=1"
      "i915.disable_power_well=1"
      "i915.enable_fbc=1"
      "i915.enable_psr=1"
      "iwlwifi.power_save=1"
    ];

    tmp.useTmpfs = true;
    loader.grub = {
      enable = true;
      device = "/dev/sda";
    };
  };

  hardware = {
    cpu.intel.updateMicrocode = true;
    enableRedistributableFirmware = true;
  };

  services.thermald.enable = true;

  services.thinkfan = {
    enable = true;

    sensors = [
      { type = "tpacpi"; query = "/proc/acpi/ibm/thermal"; indices = [ 0 ]; }
    ];

    fans = [
      { type = "tpacpi"; query = "/proc/acpi/ibm/fan"; }
    ];

    levels = [
      [ 0 0 55 ]
      [ 1 48 60 ]
      [ 2 50 61 ]
      [ 3 52 63 ]
      [ 4 56 65 ]
      [ 5 59 66 ]
      [ 7 63 80 ]
      [ "level auto" 80 32767 ]
    ];
  };

  services.tlp = {
    enable = true;

    settings = {
      # When no power supply is detected, force battery mode by default
      TLP_DEFAULT_MODE = "BAT";
      TLP_PERSISTENT_DEFAULT = 1;

      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_SCALING_GOVERNOR_ON_AC = "ondemand";

      # Enable runtime power management for PCI(e) bus devices while on AC
      RUNTIME_PM_ON_AC = "auto";

      # Prevent battery from charging fully to preserve lifetime
      # `tlp fullcharge` will override
      # Check by how much battery life has been reduced (fish):
      # $ set -l current (cat /sys/class/power_supply/BAT0/charge_full)
      # $ set -l factory (cat /sys/class/power_supply/BAT0/charge_full_design)
      # $ math "100-$current/$factory*100"
      START_CHARGE_THRESH_BAT0 = 67;
      STOP_CHARGE_THRESH_BAT0 = 100;

      # Limit CPU speed to reduce heat and increase battery
      CPU_MAX_PERF_ON_AC = "100";
      CPU_MAX_PERF_ON_BAT = "60";
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
      fsType = "ext4";
    };

    "/nix" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "btrfs";
      options = [
        "subvol=nix"
        "noatime"
        "compress-force=zstd:3"
        "discard=async"
      ];
    };

    "/state" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "btrfs";
      options = [
        "subvol=state"
        "noatime"
        "compress-force=zstd:3"
        "discard=async"
      ];
      neededForBoot = true;
    };
  };

  environment.persistence."/state" = {
    enable = true;

    users.electro.directories = [
      ".cache"
      ".mozilla"
      "documents"
      "downloads"
      "pictures"
      { directory = ".ssh"; mode = "0700"; }
    ];
  };

  networking = {
    hostName = "venus";

    dhcpcd.enable = false;
    useDHCP = false;
    useNetworkd = true;
    wireless.iwd = {
      enable = true;

      settings = {
        Settings.AutoConnect = true;
        General.EnableNetworkConfiguration = false;
        Network.EnableIPv6 = false;
        Scan.DisablePeriodicScan = true;
      };
    };
  };

  systemd.network = {
    enable = true;
    wait-online.anyInterface = true;

    networks = {
      "40-wired" = {
        name = "eno0";

        DHCP = "yes";
        dns = [ "9.9.9.9" ];

        networkConfig.LinkLocalAddressing = "no";
        dhcpV4Config.RouteMetric = 10;
      };

      "40-wireless" = {
        name = "wlan0";

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
        name = "enp0s2*";

        DHCP = "yes";
        dns = [ "9.9.9.9" ];

        networkConfig = {
          IgnoreCarrierLoss = "yes";
          LinkLocalAddressing = "no";
        };

        dhcpV4Config.RouteMetric = 30;
      };
    };

    links."40-wireless-random-mac" = {
      matchConfig.Type = "wlan0";
      linkConfig.MACAddressPolicy = "random";
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
      root.hashedPasswordFile = config.sops.secrets.rootPassword.path;
      electro = {
        isNormalUser = true;
        hashedPasswordFile = config.sops.secrets.electroPassword.path;
        extraGroups = [ "wheel" ];
        uid = 1000;
        openssh.authorizedKeys.keyFiles = [
          ../terra/ssh_electro_ed25519_key.pub
        ];
      };
    };
  };
}
