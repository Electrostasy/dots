{ pkgs, ... }:

{
  imports = [
    ../../profiles/minimal.nix
    ../../profiles/shell.nix
    ../../profiles/ssh.nix
    ../../profiles/tailscale.nix
    ../../profiles/zramswap.nix
    ../../users/electro
  ];

  nixpkgs.hostPlatform.system = "aarch64-linux";

  image.modules.default.imports = [
    ../../profiles/image/expand-root.nix
    ../../profiles/image/generic-extlinux.nix
    ../../profiles/image/interactive.nix
  ];

  hardware.deviceTree = {
    name = "rockchip/rk3588-nanopc-t6-lts.dtb";

    overlays = [
      {
        name = "led-indicators-overlay";
        dtsFile = ./led-indicators.dtso;
      }
      {
        name = "fan-control-overlay";
        dtsFile = ./fan-control.dtso;
      }
    ];
  };

  boot = {
    loader.generic-extlinux-compatible.enable = true;

    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      # Enable serial console over USB-C debug UART port.
      "8250.nr_uarts=1"
      "console=ttyS0,1500000"
    ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "ext4";
    };

    "/boot" = {
      device = "/dev/disk/by-label/BOOT";
      fsType = "vfat";
      options = [ "umask=0077" ];
    };
  };

  services.journald.storage = "volatile";

  system.stateVersion = "24.11";
}
