{ config, pkgs, lib, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/profiles/minimal.nix"
    ../../profiles/shell
    ../../profiles/ssh
    ../../profiles/tailscale.nix
    ./klipper.nix
  ];

  nixpkgs.hostPlatform.system = "aarch64-linux";

  image.modules = lib.mkForce { raw = ./image.nix; };

  sops = {
    defaultSopsFile = ./secrets.yaml;

    secrets = {
      wpa_supplicant = {};
      electroPassword.neededForUsers = true;
      electroIdentity = {
        mode = "0400";
        owner = config.users.users.electro.name;
      };
    };
  };

  boot = {
    loader.generic-extlinux-compatible.enable = true;

    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      # Required to enable serial console:
      # https://forums.raspberrypi.com/viewtopic.php?t=246215#p1659905
      "8250.nr_uarts=1"
      "console=ttyS0,115200"
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

  zramSwap.enable = true;

  hardware.firmware = [ pkgs.raspberrypiWirelessFirmware ];

  networking.wireless = {
    enable = true;

    secretsFile = config.sops.secrets.wpa_supplicant.path;
    networks = {
      Sukceno.pskRaw = "ext:psk_Sukceno";
      Sukceno5G.pskRaw = "ext:psk_Sukceno5G";
    };

    # On disconnected or inactive state, have wpa_supplicant try to periodically
    # reconnect.
    extraConfig = ''
      ap_scan=1
      autoscan=periodic:10
      disable_scan_offload=1
    '';
  };

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

  system.stateVersion = "24.11";
}
