{ config, pkgs, ... }:

{
  imports = [
    ../../profiles/firefox
    ../../profiles/gnome
    ../../profiles/mpv
    ../../profiles/mullvad
    ../../profiles/neovim
    ../../profiles/shell
    ../../profiles/ssh
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

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
        device = "/dev/disk/by-uuid/a408f4d3-eff8-455f-81d3-150b53265f40";
        allowDiscards = true;
        bypassWorkqueues = true;
      };

      availableKernelModules = [
        "ahci"
        "ehci_pci"
        "sd_mod"
        "sdhci_pci"
        "usb_storage"
        "xhci_pci"
      ];
    };

    plymouth.enable = true;

    kernelPackages = pkgs.linuxPackages_latest;

    kernelModules = [ "i915" ];

    kernelParams = [
      "acpi.ec_no_wakeup=1"
      "i915.disable_power_well=1"
      "i915.enable_fbc=1"
      "i915.enable_psr=1"
      "iwlwifi.power_save=1"
    ];

    loader.grub = {
      enable = true;
      device = "/dev/sda";
    };
  };

  hardware = {
    cpu.intel.updateMicrocode = true;
    enableRedistributableFirmware = true;
    graphics.extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libvdpau-va-gl
    ];
  };

  environment.variables.VDPAU_DRIVER = "va_gl";

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

  # Can only use one of these.
  services.power-profiles-daemon.enable = false;
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

    # Ensure time out appears when the actual physical device fails to appear,
    # otherwise, systemd cannot set the infinite timeout (such as when using
    # /dev/disk/by-* symlinks) for entering the passphrase:
    # https://github.com/NixOS/nixpkgs/issues/250003#issuecomment-1724708072
    "/nix" = {
      device = "/dev/mapper/cryptroot";
      fsType = "btrfs";
      options = [
        "subvol=nix"
        "noatime"
        "compress-force=zstd:3"
        "discard=async"
      ];
    };

    "/state" = {
      device = "/dev/mapper/cryptroot";
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

  environment.persistence.state = {
    enable = true;

    users.electro.directories = [
      "Documents"
      "Downloads"
      "Pictures"
    ];
  };

  environment.systemPackages = with pkgs; [
    gnomeExtensions.fullscreen-to-empty-workspace

    libreoffice-fresh
    rnote
  ];

  programs.dconf.profiles.user.databases = [{
    settings."org/gnome/shell/extensions/fullscreen-to-empty-workspace".move-window-when-maximized = false;
  }];

  systemd.network = {
    networks."40-wireless" = {
      matchConfig.WLANInterfaceType = "station";
      dhcpV4Config.Anonymize = true;
    };

    links."40-wireless" = {
      matchConfig.WLANInterfaceType = "station";
      linkConfig.MACAddressPolicy = "random";
    };
  };

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
    ];
  };

  system.stateVersion = "23.11";
}
