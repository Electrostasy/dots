{ config, pkgs, lib, ... }:

{
  nixpkgs.hostPlatform = "aarch64-linux";

  system.stateVersion = "23.05";

  boot = {
    tmp.useTmpfs = true;
    kernelParams = [ "cma=256M" ];
    kernelPackages = pkgs.linuxKernel.packages.linux_rpi4;

    loader = {
      generic-extlinux-compatible.enable = false;
      efi.canTouchEfiVariables = false;

      # The proprietary Raspberry Pi bootloader chainboots Tow-Boot, which acts
      # as our platform firmware. Tow-Boot chainboots into systemd-boot for
      # starting NixOS. Device trees and overlays are loosely tied to the
      # kernel, so we use systemd-boot to manage the relevant files.
      systemd-boot = {
        enable = true;

        extraFiles = let inherit (config.boot.kernelPackages) kernel; in {
          "firmware/bcm2711-rpi-4-b.dtb" = "${kernel}/dtbs/broadcom/bcm2711-rpi-4-b.dtb";

          # IMX708 driver is not fully upstreamed to mainline yet:
          # https://patchwork.kernel.org/project/linux-media/list/?series=715172
          "firmware/overlays/imx708.dtbo" = "${kernel}/dtbs/overlays/imx708.dtbo";

          "firmware/config.txt" = pkgs.writeText "config.txt" ''
            [pi4]
            kernel=Tow-Boot.noenv.rpi4.bin
            enable_gic=1
            armstub=armstub8-gic.bin
            disable_overscan=1

            [all]
            arm_64bit=1
            enable_uart=1
            avoid_warnings=1
            devicetree=bcm2711-rpi-4-b.dtb

            # Pi Camera Module 3 (Sony IMX708) support.
            camera_auto_detect=0
            dtoverlay=imx708
          '';
        };
      };
    };
  };

  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = [
        "defaults"
        "size=256M"
        "mode=755"
      ];
    };

    "/boot" = {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };

    "/boot/firmware" = {
      device = "/dev/disk/by-label/TOW-BOOT-FI";
      fsType = "vfat";
    };

    "/nix" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "btrfs";
      options = [
        "subvol=nix"
        "noatime"
        "nodiratime"
        "compress-force=zstd:3"
      ];
    };

    "/state" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "btrfs";
      options = [
        "subvol=state"
        "noatime"
        "nodiratime"
        "compress-force=zstd:3"
      ];
      neededForBoot = true;
    };
  };

  # Raspberry Pi 4 does not have a RTC and timesyncd is fighting with resolved
  # due to DNSSEC and expired signatures, so for now just synchronize time
  # with local network router ("DNSSEC validation failed: signature-expired").
  services.timesyncd.servers = lib.mkForce [ "192.168.205.1" ];

  environment.persistence."/state".enable = true;
  environment.systemPackages = with pkgs; [
    libcamera-apps
    libgpiod
    libraspberrypi
    vim
  ];

  services.udev.extraRules = ''
    # In order to not have to use /dev/serial/by-id/usb-Prusa_Research__prus...
    # to communicate with the 3D printer's serial socket.
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="2c99", ATTRS{idProduct}=="0002", SYMLINK+="ttyMK3S"
  '';

  services.klipper = {
    enable = true;

    user = "klipper";
    group = "klipper";

    firmwares.einsy = {
      enable = true;
      serial = "/dev/ttyMK3S";
      configFile = ./einsy.config;
    };

    # firmwares.rp2040 = {
    #   enable = true;
    #   serial = "/dev/serial/by-id/usb-Klipper_rp2040_E6611032E37D2734-if00";
    #   configFile = ./rp2040.config;
    # };

    configFile = ./printer-prusa-mk3s.cfg;
  };

  services.moonraker = {
    enable = true;

    settings.authorization = {
      force_logins = true;
      cors_domains = [ "http://localhost:80" ];
      trusted_clients = [
        "10.0.0.0/8"
        "127.0.0.0/8"
      ];
    };
  };

  # Necessary to grant the Linux user `moonraker` access to the /run/klipper/api
  # UNIX domain socket.
  users.groups.klipper = { };
  users.users.moonraker.extraGroups = [ "klipper" ];
  users.users.klipper = {
    isSystemUser = true;
    group = "klipper";
  };

  services.mainsail.enable = true;

  networking = {
    hostName = "phobos";

    dhcpcd.enable = false;
    useDHCP = false;
    firewall.allowedTCPPorts = [ 80 ];
    firewall.allowedUDPPorts = [ 80 ];
  };

  systemd.network = {
    enable = true;

    networks."40-wired" = {
      name = "en*";

      DHCP = "yes";
      dns = [ "9.9.9.9" ];
    };
  };

  documentation.enable = false;

  sops = {
    defaultSopsFile = ./secrets.yaml;

    secrets = {
      piPassword.neededForUsers = true;
      sshHostKey = { };
    };
  };

  services.openssh.hostKeys = [
    { type = "ed25519"; inherit (config.sops.secrets.sshHostKey) path; }
  ];

  users.mutableUsers = false;
  users.users.pi = {
    isNormalUser = true;
    passwordFile = config.sops.secrets.piPassword.path;
    extraGroups = [ "wheel" ];
    uid = 1000;
    openssh.authorizedKeys.keyFiles = [
      ../jupiter/ssh_gediminas_ed25519_key.pub
      ../terra/ssh_electro_ed25519_key.pub
      ../venus/ssh_electro_ed25519_key.pub
    ];
  };
}
