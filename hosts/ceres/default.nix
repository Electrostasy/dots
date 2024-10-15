{ config, pkgs, ... }:

{
  imports = [
    ../../profiles/firefox
    ../../profiles/gnome
    ../../profiles/mpv
    ../../profiles/neovim
    ../../profiles/shell
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets.electroPassword.neededForUsers = true;
  };

  boot = {
    initrd.availableKernelModules = [
      "ahci"
      "ehci_pci"
      "sd_mod"
      "sr_mod"
      "usbhid"
      "usb_storage"
      "xhci_pci"
    ];
    kernelModules = [ "kvm-intel" ];
    kernelPackages = pkgs.linuxPackages_latest;

    loader.grub = {
      enable = true;
      device = "/dev/sda";
    };
  };

  hardware = {
    cpu.intel.updateMicrocode = true;
    enableRedistributableFirmware = true;
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
      options = [ "subvol=nix" "noatime" "compress-force=zstd:3" ];
    };

    "/state" = {
      device = "/dev/disk/by-label/data";
      fsType = "btrfs";
      options = [ "subvol=state" "noatime" "compress-force=zstd:3" ];
      neededForBoot = true;
    };
  };

  environment.persistence.state = {
    enable = true;

    users.electro.directories = [
      "Visiems"
    ];
  };

  environment.systemPackages = with pkgs; [
    libewf
    virt-manager
  ];

  systemd.network.networks."40-wired" = {
    name = "en*";
    gateway = [ "192.168.100.1" ];
    address = [ "192.168.100.80/24" ];
    dns = [ "192.168.100.10" "212.59.1.1" ];

    networkConfig.DHCP = false;
  };

  services.tailscale.enable = false;

  services.samba = {
    enable = true;
    openFirewall = true;

    settings = {
      global = {
        "map to guest" = "bad user";
        "load printers" = "no";
        "printcap name" = "/dev/null";

        "log file" = "/var/log/samba/client.%I";
        "log level" = 2;
      };

      Visiems = {
        "path" = "/home/electro/Visiems";
        "browseable" = true;
        "writable" = true;
        "public" = true;

        # Allow everyone to add/remove/modify files/directories.
        "guest ok" = "yes";
        "force user" = "nobody";
        "force group" = "nogroup";

        # Default permissions for files/directories.
        "create mask" = 0666;
        "directory mask" = 0777;
      };
    };
  };

  virtualisation.libvirtd = {
    enable = true;
    qemu.package = pkgs.qemu_kvm;
  };

  users.users.electro = {
    isNormalUser = true;
    uid = 1000;

    hashedPasswordFile = config.sops.secrets.electroPassword.path;

    extraGroups = [
      "wheel" # allow using `sudo` for this user.
      "libvirtd" # allow passwordless access to the `libvirt` daemon.
    ];
  };

  system.stateVersion = "22.05";
}
