{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules =
    [ "xhci_pci" "ehci_pci" "ahci" "nvme" "usb_storage" "usbhid" "sd_mod" ];

  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      # Required permissions for sshd to be happy
      options = [ "defaults" "size=4G" "mode=755" ];
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/B9B8-94A8";
      fsType = "vfat";
    };

    "/nix" = {
      device = "/dev/disk/by-uuid/5e459add-acb1-464c-9560-74d4b9b7f7d1";
      fsType = "ext4";
    };
  };

  environment.persistence."/nix/state" = {
    hideMounts = true;
    directories = [ "/etc/nixos" "/etc/ssh" "/var/log" ];
    files = [ "/etc/machine-id" ];
    users.electro.directories = [
      ".cache/nix-index"
      ".cache/tealdeer"
      { directory = ".ssh"; mode = "0700"; }
      ".mozilla"
      "Pictures"
    ];
  };

  swapDevices = [ ];
}
