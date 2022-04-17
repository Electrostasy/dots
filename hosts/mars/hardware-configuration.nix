{ config, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "sd_mod" ];
    kernelModules = [ "kvm-intel" ];
  };

  hardware = {
    cpu.intel.updateMicrocode = true;
    enableRedistributableFirmware = true;
  };

  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = [ "defaults" "size=512M" "mode=755" ];
    };

    "/boot" = {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };

    "/nix" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "btrfs";
      options = [ "subvol=nix" "noatime" "nodiratime" "compress=zstd" "ssd" ];
    };

    "/state" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "btrfs";
      options = [ "subvol=state" "noatime" "nodiratime" "compress=zstd" "ssd" ];
      neededForBoot = true;
    };
  };

  environment.persistence."/state" = {
    hideMounts = true;
    directories = [ "/etc/nixos" "/etc/ssh" "/var/log" ];
    files = [ "/etc/machine-id" ];
    users.electro.directories = [
      ".cache"
      ".config/SchildiChat"
      { directory = ".ssh"; mode = "0700"; }
      ".mozilla"
      "Pictures"
    ];
  };

  swapDevices = [ ];
}
