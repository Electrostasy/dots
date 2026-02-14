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
    ../../profiles/image/generic-efi.nix
    ../../profiles/image/interactive.nix
  ];

  hardware.deviceTree = {
    name = "rockchip/rk3576-armsom-sige5.dtb";

    overlays = [
      {
        name = "red-led-on-panic-overlay";
        dtsFile = ./red-led-on-panic.dtso;
      }
    ];
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = false;
    };

    # TODO: Missing PWM/thermal subsystem support, but mainline boots now!
    kernelPackages = pkgs.linuxPackages_testing;
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

  services.journald = {
    storage = "volatile";

    upload = {
      enable = true;

      settings.Upload.URL = "http://phobos.sol.tailnet.0x6776.lt";
    };
  };

  system.stateVersion = "25.05";
}
