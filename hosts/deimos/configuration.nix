{ config, pkgs, lib, ... }:

{
  networking.hostName = "deimos";
  system.stateVersion = "21.11";

  boot = {
    loader = {
      grub.enable = false;
      raspberryPi = {
        enable = true;
        version = 4;
      };
    };
    consoleLogLevel = lib.mkDefault 7;
    kernelPackages = pkgs.linuxPackages_rpi4;
    kernelParams = [
      # Allow using all of the RAM
      "cma=64M"
      "console=tty0"
      "console=ttyAMA0,115200"
      "8250.nr_uarts=1"
    ];
    # Remove some kernel modules added for AllWinner SOCs that are not available
    # for RPi's kernel
    initrd.availableKernelModules = [
      # Allows early (earlier) modesetting for the Raspberry Pi
      "vc4" "bcm2835_dma" "i2c_bcm2835"
    ];
  };

  fileSystems = lib.mkForce {
    # There is no U-Boot on the Pi4, firmware part needs to be mounted as /boot
    "/boot" = {
      device = "/dev/disk/by-label/FIRMWARE";
      fsType = "vfat";
    };
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };
  };
}
