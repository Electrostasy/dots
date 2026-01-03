{ pkgs, ... }:

{
  imports = [
    ../../profiles/minimal.nix
    ../../profiles/shell.nix
    ../../profiles/ssh.nix
    ../../profiles/tailscale.nix
    ../../users/electro
  ];

  nixpkgs.hostPlatform.system = "aarch64-linux";

  image.modules.default.imports = [
    ../../profiles/image/expand-root.nix
    ../../profiles/image/generic-efi.nix
    ../../profiles/image/interactive.nix
  ];

  hardware.deviceTree = {
    name = "rockchip/rk3588-armsom-sige7.dtb";

    overlays = [
      {
        name = "red-led-on-panic-overlay";
        dtsFile = ./red-led-on-panic.dtso;
      }
      {
        name = "fan-control-overlay";
        dtsFile = ./fan-control.dtso;
      }
    ];
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = false;
    };

    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [ "8250.nr_uarts=1" ];

    initrd = {
      systemd.root = "gpt-auto";
      supportedFilesystems.ext4 = true;
    };
  };

  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 15d";
    };

    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };
  };

  zramSwap.enable = true;

  services.journald.storage = "volatile";

  system.stateVersion = "25.05";
}
