{ config, pkgs, lib, ... }:

{
  imports = [ ./remote-build-machines.nix ];

  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "22.11";

  boot = {
    initrd.availableKernelModules = [
      "ahci"
      "ehci_pci"
      "sdhci_pci"
      "sd_mod"
      "usb_storage"
    ];

    kernelModules = [ "kvm-intel" ];
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "acpi.ec_no_wakeup=1"
      "i915.disable_power_well=1"
      "i915.enable_fbc=1"
      "i915.enable_psr=1"
      "iwlwifi.power_save=1"
    ];

    tmpOnTmpfs = true;
    loader.grub = {
      enable = true;
      version = 2;
      device = "/dev/sda";
    };
  };

  hardware.cpu.intel.updateMicrocode = true;

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
      START_CHARGE_THRESH_BAT0 = 40;
      STOP_CHARGE_THRESH_BAT0 = 80;

      # Limit CPU speed to reduce heat and increase battery
      CPU_MAX_PERF_ON_AC = "100";
      CPU_MAX_PERF_ON_BAT = "60";
    };
  };

  services.acpid = {
    enable = true;

    # The uevent for attribute "hotkey_tablet_mode" never fires even if its sysfs value
    # at /devices/platform/thinkpad_acpi mutates, so we can't use udev to handle this
    handlers.tabletMode = {
      event = "video/tabletmode TBLT 0000008A 0000000[01]";
      action = ''
        IFS=" " read -r -a ARGV <<< "$@"
        mapfile -t SESSIONS < <(${pkgs.systemd}/bin/loginctl list-sessions -o json | ${pkgs.jq}/bin/jq -cM '.[].uid')
        for SESSION in "''${SESSIONS[@]}"; do
          # Ensure the login session has an active Wayland server
          GFX_SESSION=$(${pkgs.findutils}/bin/find "/run/user/$SESSION" -maxdepth 1 -name 'wayland-[0-9]')
          if [[ -z "$GFX_SESSION" ]]; then
            continue
          fi
          XDG_RUNTIME_DIR="$(dirname "$GFX_SESSION")"
          WAYLAND_DISPLAY="$(basename "$GFX_SESSION")"
          export XDG_RUNTIME_DIR
          export WAYLAND_DISPLAY

          TRANSFORM=$([ "''${ARGV[3]:0-1}" = "1" ] && echo "180" || echo "normal")
          ${pkgs.wlr-randr}/bin/wlr-randr --output LVDS-1 --transform "$TRANSFORM"
        done
      '';
    };
  };

  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = [ "defaults" "size=1G" "mode=755" ];
    };

    "/boot" = {
      device = "/dev/disk/by-label/boot";
      fsType = "ext4";
    };

    "/nix" = {
      device = "/dev/disk/by-label/data";
      fsType = "btrfs";
      options = [ "subvol=nix" "noatime" "nodiratime" "compress-force=zstd:3" ];
    };

    "/state" = {
      device = "/dev/disk/by-label/data";
      fsType = "btrfs";
      options = [ "subvol=state" "noatime" "nodiratime" "compress-force=zstd:3" ];
      neededForBoot = true;
    };
  };

  environment.persistence."/state" = {
    users.electro.directories = [
      ".cache"
      ".mozilla"
      { directory = ".ssh"; mode = "0700"; }
    ];
  };

  time.timeZone = "Europe/Vilnius";
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

  services.timesyncd.servers = [
    "1.europe.pool.ntp.org"
    "1.lt.pool.ntp.org"
    "2.europe.pool.ntp.org"
  ];

  systemd.network = {
    enable = true;
    wait-online.anyInterface = true;

    networks = {
      "40-wired" = {
        name = "eno0";

        DHCP = "yes";
        dns = [ "127.0.0.1" "::1" ];

        networkConfig.LinkLocalAddressing = "no";
        dhcpV4Config.RouteMetric = 10;
      };

      "40-wireless" = {
        name = "wlan0";

        DHCP = "yes";
        dns = [ "127.0.0.1" "::1" ];

        networkConfig = {
          IgnoreCarrierLoss = "yes";
          LinkLocalAddressing = "no";
        };

        dhcpV4Config = {
          Anonymize = true;
          RouteMetric = 20;
        };
      };

      # NOTE: Only works if the wifi card is powered down:
      # $ sudo networkctl down wlan0
      "40-tethered" = {
        name = "enp0s2[69]u1u[12]";

        DHCP = "yes";
        dns = [ "127.0.0.1" "::1" ];

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
      root.passwordFile = config.sops.secrets.rootPassword.path;
      electro = {
        isNormalUser = true;
        passwordFile = config.sops.secrets.electroPassword.path;
        extraGroups = [ "wheel" ];
        uid = 1000;
        shell = pkgs.fish;
        openssh.authorizedKeys.keyFiles = [
          ../terra/ssh_electro_ed25519_key.pub
        ];
      };
    };
  };
}
