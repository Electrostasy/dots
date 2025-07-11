{ config, pkgs, flake, ... }:

{
  imports = [
    ../../profiles/firefox.nix
    ../../profiles/gnome
    ../../profiles/mpv.nix
    ../../profiles/mullvad
    ../../profiles/neovim
    ../../profiles/shell
    ../../profiles/ssh
    ../../profiles/tailscale.nix
    ../luna/nfs-share.nix
    ./audio.nix
    ./gaming.nix
  ];

  nixpkgs = {
    hostPlatform.system = "x86_64-linux";
    overlays = [
      flake.overlays.qemu-unshare-fix
      flake.overlays.sonic-visualiser-update
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
        "xhci_pci"
        "ahci"
        "nvme"
        "usbhid"
        "sd_mod"
      ];
    };

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

  programs.dconf.profiles.user.databases = [{
    settings."org/gnome/shell/extensions/tilingshell".selected-layouts = [ [ "50% Horizontal Split" "50% Vertical Split" ] ];
  }];

  environment.systemPackages = with pkgs; [
    freecad
    gimp3
    kicad
    libreoffice-fresh
    picard
    prusa-slicer
    sonic-lineup
    sonic-visualiser
  ];

  hardware = {
    cpu.intel.updateMicrocode = true;
    enableRedistributableFirmware = true;
    keyboard.qmk.enable = true;
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
  };

  swapDevices = [
    { device = "/dev/disk/by-partuuid/212fa8ad-6681-44ff-9df4-1cf6b0df55be"; randomEncryption.enable = true; }
  ];

  preservation = {
    enable = true;

    preserveAt."/persist/state".users.electro.directories = [
      ".config/FreeCAD"
      ".config/MusicBrainz"
      ".config/PrusaSlicer"
      ".config/kicad"
      ".local/share/FreeCAD"
      ".local/share/kicad"
    ];
  };

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

  networking.firewall.interfaces.${config.services.tailscale.interfaceName}.allowedTCPPorts = [ config.services.prometheus.exporters.node.port ];
  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [ "cpu.info" ];
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
      ../mercury/id_ed25519.pub
      ../venus/id_ed25519.pub
    ];
  };

  system.stateVersion = "24.11";
}
