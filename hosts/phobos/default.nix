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

  image.modules.default.imports = [
    ../../profiles/image/expand-root.nix
    ../../profiles/image/generic-efi.nix
    ../../profiles/image/interactive.nix
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

  hardware.deviceTree.name = "broadcom/bcm2711-rpi-4-b.dtb";

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = false;
    };

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
