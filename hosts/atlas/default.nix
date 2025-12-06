{ config, pkgs, ... }:

{
  imports = [
    ../../profiles/minimal.nix
    ../../profiles/shell
    ../../profiles/ssh
    ../../profiles/tailscale.nix
  ];

  nixpkgs.hostPlatform.system = "aarch64-linux";

  image.modules.default.imports = [
    ../../profiles/image/expand-root.nix
    ../../profiles/image/generic-efi.nix
    ../../profiles/image/interactive.nix
  ];

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

    initrd.systemd.root = "gpt-auto";
    supportedFilesystems.ext4 = true;
  };

  zramSwap.enable = true;

  services.journald.storage = "volatile";

  users.users.electro = {
    isNormalUser = true;
    uid = 1000;

    hashedPasswordFile = config.sops.secrets.electroPassword.path;
    extraGroups = [ "wheel" ];

    openssh.authorizedKeys.keyFiles = [
      ../mercury/id_ed25519.pub
      ../terra/id_ed25519.pub
      ../venus/id_ed25519.pub
    ];
  };

  system.stateVersion = "25.05";
}
