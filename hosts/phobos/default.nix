{ config, ... }:

{
  imports = [
    ../../profiles/minimal.nix
    ../../profiles/shell
    ../../profiles/ssh
    ../../profiles/tailscale.nix
    ./acme.nix
    ./dendrite.nix
    ./discord-transcriber.nix
    ./fileserver.nix
    ./headscale.nix
    ./hostapd.nix
    ./prometheus.nix
  ];

  nixpkgs.hostPlatform.system = "aarch64-linux";

  nixpkgs.overlays = [
    # If our bootloader EEPROM version from raspberrypi/rpi-eeprom is too new,
    # then we need accordingly new firmware files or else we will not be able
    # to boot.
    # TODO: Remove when it is updated in nixpkgs.
    (final: prev: {
      raspberrypifw = prev.raspberrypifw.overrideAttrs (finalAttrs: oldAttrs: {
        version = "1.20250305";

        src = oldAttrs.src.override {
          rev = null;
          tag = finalAttrs.version;
          hash = "sha256-J2Na7yGKvRDWKC+1gFEQMuaam+4vt+RsV9FjarDgvMs=";
        };
      });
    })
  ];

  image.modules.default.imports = [
    ../../profiles/image/expand-root.nix
    ../../profiles/image/generic-extlinux.nix
    ../../profiles/image/platform/raspberrypi-4-b.nix
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

  boot = {
    loader.generic-extlinux-compatible.enable = true;

    kernelParams = [ "8250.nr_uarts=1" ];
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

  zramSwap.enable = true;

  networking.firewall.interfaces.${config.services.tailscale.interfaceName}.allowedTCPPorts = [ config.services.prometheus.exporters.node.port ];
  services.prometheus.exporters.node.enable = true;

  services.journald.storage = "volatile";

  users.users.electro = {
    isNormalUser = true;
    uid = 1000;

    # Change password using:
    # $ nix run nixpkgs#mkpasswd -- -m SHA-512 -s
    hashedPasswordFile = config.sops.secrets.electroPassword.path;

    extraGroups = [
      "wheel" # allow using `sudo` for this user.
    ];

    openssh.authorizedKeys.keyFiles = [
      ../mercury/id_ed25519.pub
      ../terra/id_ed25519.pub
      ../venus/id_ed25519.pub
    ];
  };

  system.stateVersion = "25.05";
}
