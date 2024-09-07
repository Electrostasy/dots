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
    ../luna/nfs-share.nix
    ./audio.nix
    ./gaming.nix
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
        device = "/dev/disk/by-partuuid/6e31b86f-1d1d-4cd8-91b3-79af16dda198";
        allowDiscards = true;
      };

      systemd = {
        # https://github.com/NixOS/nixpkgs/issues/309316
        storePaths = with pkgs; [
          "${util-linux}/bin/mount"
          "${util-linux}/bin/umount"
          "${btrfs-progs}/bin/btrfs"
          "${coreutils}/bin/cut"
        ];

        services.cryptroot-restore = {
          description = "Restore root filesystem for impermanent btrfs root";
          wantedBy = [ "sysinit.target" ];

          after = [ "cryptsetup.target" ]; # after /dev/mapper/cryptroot is available.
          before = [ "local-fs-pre.target" ]; # before filesystems are mounted.

          path = with pkgs; [
            util-linux
            btrfs-progs
            coreutils
          ];

          unitConfig.DefaultDependencies = "no";
          serviceConfig.Type = "oneshot";

          # In order to restore the root subvolume from an empty snapshot, first
          # the lower level subvolumes under /root need to be deleted, which seem
          # to get created by systemd.
          script = ''
            mkdir -p /mnt
            mount -t btrfs -o subvol=/ /dev/mapper/cryptroot /mnt

            for subvolume in $(btrfs subvolume list -o /mnt/root | cut -f9 -d' '); do
              echo "Deleting /$subvolume subvolume..."
              btrfs subvolume delete "/mnt/$subvolume"
            done

            if [ $? -eq 0 ]; then
              echo "Deleting /root subvolume..."
              btrfs subvolume delete /mnt/root

              echo "Restoring /root subvolume from blank snapshot..."
              btrfs subvolume snapshot /mnt/root-blank /mnt/root
            else
              echo "Failed to delete subvolumes under /mnt/root!"
            fi

            umount /mnt
          '';
        };
      };

      availableKernelModules = [
        "xhci_pci"
        "ahci"
        "nvme"
        "usbhid"
        "sd_mod"
      ];
    };

    kernelModules = [ "kvm-intel" ];
    kernelPackages = pkgs.linuxPackages_latest;

    tmp.tmpfsSize = "75%";

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    binfmt.emulatedSystems = [ "aarch64-linux" ];
  };

  programs.dconf.profiles.user.databases = [{
    settings."org/gnome/shell/extensions/tilingshell".selected-layouts = [
      "1/1 V-Split"
      "1/1 H-Split"
    ];
  }];

  environment.systemPackages = with pkgs; [
    flacon
    freecad-wayland
    gimp
    kicad
    libreoffice-fresh
    nurl
    pastel
    picard
    prusa-slicer
    pt-p300bt-labelmaker
    sonic-lineup
    sonic-visualiser
    via
  ];

  hardware = {
    cpu.intel.updateMicrocode = true;
    enableRedistributableFirmware = true;
    keyboard.qmk.enable = true;
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/8c588999-abbc-455e-b09f-976983d8154d";
      fsType = "btrfs";
      options = [
        "subvol=root"
        "noatime"
        "compress-force=zstd:1"
        "discard=async"
      ];
    };

    "/boot" = {
      device = "/dev/disk/by-partuuid/ed8ad820-1751-48ca-af62-4f671f64f0f4";
      fsType = "vfat";
    };

    "/nix" = {
      device = "/dev/disk/by-uuid/8c588999-abbc-455e-b09f-976983d8154d";
      fsType = "btrfs";
      options = [
        "subvol=nix"
        "noatime"
        "compress-force=zstd:1"
        "discard=async"
      ];
    };

    "/state" = {
      device = "/dev/disk/by-uuid/8c588999-abbc-455e-b09f-976983d8154d";
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

  swapDevices = [
    { device = "/dev/disk/by-partuuid/212fa8ad-6681-44ff-9df4-1cf6b0df55be"; randomEncryption.enable = true; }
  ];

  environment.persistence.state = {
    enable = true;

    users.electro = {
      files = [
        ".config/git-credential-keepassxc"
      ];

      directories = [
        ".config/FreeCAD"
        ".config/PrusaSlicer"
        ".local/share/FreeCAD"
        "Documents"
        "Downloads"
        "Pictures"
      ];
    };
  };

  # Set default mount options for mounting through udisksctl/nautilus.
  services.udisks2.settings."mount_options.conf" = {
    "/dev/disk/by-uuid/e208c920-b9e7-42e6-a38a-ef6aacbeb374" = {
      btrfs_defaults = [
        "noatime"
        "compress-force=zstd:3"
      ];
    };
  };

  systemd.network.networks."40-wired" = {
    name = "enp*";
    DHCP = "yes";
    dns = [ "9.9.9.9" ];
  };

  users.users.electro = {
    isNormalUser = true;
    uid = 1000;

    # Change password using:
    # $ nix run nixpkgs#mkpasswd -- -m SHA-512 -s
    hashedPasswordFile = config.sops.secrets.electroPassword.path;

    extraGroups = [
      "wheel" # allow using `sudo` for this user.
      "networkmanager" # don't ask password when connecting to networks.
    ];

    openssh.authorizedKeys.keyFiles = [
      ../mercury/id_ed25519.pub
      ../venus/id_ed25519.pub
    ];
  };

  system.stateVersion = "24.11";
}
