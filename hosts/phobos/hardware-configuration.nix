{ modulesPath, persistMount, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "uas" ];

  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      # Required permissions for sshd to be happy
      options = [ "defaults" "size=256M" "mode=755" ];
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

  environment.persistence.${persistMount} = {
    directories = [ "/etc/nixos" "/etc/ssh" "/var/log" ];
    files = [ "/etc/machine-id" ];
  };

  swapDevices = [{ device = "/dev/disk/by-label/swap"; }];

}
