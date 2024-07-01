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

  boot = {
    initrd = {
      luks.devices."cryptroot" = {
        device = "/dev/disk/by-partuuid/6e31b86f-1d1d-4cd8-91b3-79af16dda198";
        allowDiscards = true;

        # In order to restore the root subvolume from an empty snapshot, first
        # the lower level subvolumes under /root which seem to get created by
        # systemd need to be deleted.
        postOpenCommands = ''
          mkdir -p /mnt
          mount -o subvol=/ /dev/mapper/cryptroot /mnt

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

    tmp = {
      useTmpfs = true;
      # Use a higher than default (50%) upper limit for /tmp to not run out of
      # space compiling programs.
      tmpfsSize = "75%";
    };

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    binfmt.emulatedSystems = [ "aarch64-linux" ];
  };

  environment.systemPackages = with pkgs; [
    flacon
    freecad
    gimp
    kicad
    libreoffice-fresh
    nurl
    pastel
    picard
    prusa-slicer
    pt-p300bt-labelmaker
    spek
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

  networking = {
    dhcpcd.enable = false;
    useDHCP = false;
    useNetworkd = true;
  };

  systemd.network = {
    enable = true;

    networks."40-wired" = {
      name = "enp*";

      DHCP = "yes";
      dns = [ "9.9.9.9" ];
    };
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

  users = {
    mutableUsers = false;

    # Change password using:
    # $ nix run nixpkgs#mkpasswd -- -m SHA-512 -s
    users.electro = {
      isNormalUser = true;
      hashedPasswordFile = config.sops.secrets.electroPassword.path;
      extraGroups = [ "wheel" ];
      uid = 1000;
      openssh.authorizedKeys.keyFiles = [
        ../mercury/ssh_host_ed25519_key.pub
        ../venus/ssh_host_ed25519_key.pub
      ];
    };
  };

  system.stateVersion = "24.11";
}
