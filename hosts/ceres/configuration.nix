{ config, pkgs, ... }:

{
  system.stateVersion = "22.05";

  nixpkgs.hostPlatform = "x86_64-linux";

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
    enable = true;

    users.gediminas.directories = [
      ".cache"
      { directory = ".ssh"; mode = "0700"; }
      "Visiems"
    ];
  };

  networking = {
    hostName = "ceres";

    dhcpcd.enable = false;
    useDHCP = false;

    defaultGateway = "192.168.100.1";
    nameservers = [
      "192.168.100.10"
      "212.59.1.1"
    ];
    interfaces.eno0.ipv4.addresses = [
      { address = "192.168.100.80"; prefixLength = 24; }
    ];
  };

  virtualisation.libvirtd = {
    enable = true;
    qemu.package = pkgs.qemu_kvm;
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;

    secrets = {
      rootPassword.neededForUsers = true;
      gediminasPassword.neededForUsers = true;
    };
  };

  users = {
    mutableUsers = false;

    users = {
      root.passwordFile = config.sops.secrets.rootPassword.path;
      gediminas = {
        isNormalUser = true;
        passwordFile = config.sops.secrets.gediminasPassword.path;
        extraGroups = [ "wheel" "libvirtd" ];
        uid = 1000;
      };
    };
  };

  services.samba = {
    enable = true;
    openFirewall = true;

    extraConfig = ''
      map to guest = bad user
      load printers = no
      printcap name = /dev/null

      log file = /var/log/samba/client.%I
      log level = 2
    '';

    shares."Visiems" = {
      path = "/home/gediminas/Visiems";
      browseable = true;
      writable = true;
      public = true;

      # Allow everyone to add/remove/modify files/directories
      "guest ok" = "yes";
      "force user" = "nobody";
      "force group" = "nogroup";

      # Default permissions for files/directories
      "create mask" = 0666;
      "directory mask" = 0777;
    };
  };
}
