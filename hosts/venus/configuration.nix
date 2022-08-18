{ config, pkgs, lib, persistMount, ... }:

{
  imports = [ ./remote-build-machines.nix ];

  system.stateVersion = "22.11";

  boot = {
    initrd.availableKernelModules = [ "ehci_pci" "ahci" "usb_storage" "sd_mod" "sdhci_pci" ];
    kernelModules = [ "kvm-intel" ];
    kernelPackages = pkgs.linuxPackages_latest;
    tmpOnTmpfs = true;
    loader.grub = {
      enable = true;
      version = 2;
      device = "/dev/sda";
    };
  };

  hardware = {
    cpu.intel.updateMicrocode = true;
    enableRedistributableFirmware = true;
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

  environment.persistence.${persistMount} = {
    directories = [
      "/etc/nixos"
      "/etc/ssh"
      "/var/log"
    ];
    files = [ "/etc/machine-id" ];
    users.electro.directories = [
      ".cache"
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

  services.avahi.interfaces = [ "eno0" ];

  sops = {
    defaultSopsFile = ./secrets.yaml;

    secrets = {
      rootPassword.neededForUsers = true;
      electroPassword.neededForUsers = true;
      sshHostKey = { };
    };
  };

  users = {
    mutableUsers = false;

    users = {
      root.passwordFile = config.sops.secrets.rootPassword.path;
      electro = {
        isNormalUser = true;
        passwordFile = config.sops.secrets.electroPassword.path;
        extraGroups = [ "wheel" ];
        shell = pkgs.fish;
      };
    };
  };
}
