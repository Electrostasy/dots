{ config, pkgs, lib, ... }:

{
  imports = [
    ../../profiles/system/common
    ../../profiles/system/headless
    ../../profiles/system/shell
    ../../profiles/system/ssh
  ];

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

          "firmware/config.txt" = pkgs.writeText "config.txt" /* ini */ ''
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

            # Set the USB-C port as USB 2.0 host.
            otg_mode=1
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
        "compress-force=zstd:3"
      ];
    };

    "/state" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "btrfs";
      options = [
        "subvol=state"
        "noatime"
        "compress-force=zstd:3"
      ];
      neededForBoot = true;
    };
  };

  # Raspberry Pi 4 does not have a RTC and timesyncd is fighting with resolved
  # due to DNSSEC and expired signatures, so for now just synchronize time
  # with local network router ("DNSSEC validation failed: signature-expired").
  services.timesyncd.servers = lib.mkForce [ "192.168.205.1" ];

  environment = {
    persistence."/state".enable = true;

    systemPackages = with pkgs; [
      libcamera-apps
      libgpiod
      libraspberrypi
      vim

      # Expose klipper's calibrate_shaper.py because the klipper module does not.
      (writeShellApplication {
        name = "calibrate_shaper";
        runtimeInputs = [( python3.withPackages (ps: [ ps.numpy ps.matplotlib ]) )];
        text = "${klipper.src}/scripts/calibrate_shaper.py \"$@\"";
      })
    ];
  };

  services.udev.extraRules = ''
    # In order to not have to use /dev/serial/by-id/usb-Prusa_Research__prus...
    # to communicate with the 3D printer's serial socket.
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="2c99", ATTRS{idProduct}=="0002", SYMLINK+="ttyMK3S"

    # Setup Linux USB permissions for `uhubctl` to be run by users part of `dialout`:
    # https://github.com/mvp/uhubctl#linux-usb-permissions.
    SUBSYSTEM=="usb", DRIVER=="usb", MODE="0664", ATTR{idVendor}=="2109", GROUP="dialout"
    SUBSYSTEM=="usb", DRIVER=="usb", MODE="0664", ATTR{idVendor}=="1d6b", GROUP="dialout"
  '';

  # RP2040-based secondary Klipper MCUs seem to be stuck in an error state on boot,
  # giving errors such as:
  # `usb 1-1.3: device descriptor read/64, error -32`
  # `usb 1-1.3: Device not responding to setup address.`
  # Power cycling them once on boot seems to fix it and allows the main Klipper
  # service to continue launch.
  # NOTE: 3D printer has to be connected to the host USB-C port on the Pi, which
  # does not support power cycling, so `otg_mode=1` has to be set in `config.txt`.
  systemd.services.klipper-mcus-power-cycle = {
    description = "Power cycle Klipper secondary MCUs after main service loads";
    wantedBy = [ "multi-user.target" "klipper.service" ];
    after = [ "klipper.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.uhubctl}/bin/uhubctl --level 2 --action 2";
      SupplementaryGroups = [ "dialout" ];
      User = "klipper";
      Group = "klipper";
    };
  };

  services.klipper = {
    enable = true;

    user = "klipper";
    group = "klipper";

    configFile = ./mcu-prusa-mk3s.cfg;
  };

  # Set Mainsail theme from Moonraker as the default theme.
  systemd.services.moonraker.serviceConfig.ExecStartPre = pkgs.writeShellScript "set-mainsail-theme.sh" ''
    MAINSAIL_CONFIG='${config.services.moonraker.stateDir}/config/.theme/default.json'
    if [ ! -f "$MAINSAIL_CONFIG" ]; then
      mkdir -p "''${MAINSAIL_CONFIG%/*}"
      ln -s ${./mainsail-config.json} "$MAINSAIL_CONFIG"
    fi
  '';

  services.moonraker = {
    enable = true;

    settings = {
      history = { };
      authorization = {
        force_logins = true;
        cors_domains = [ "http://localhost:80" ];
        trusted_clients = [
          "10.0.0.0/8"
          "127.0.0.0/8"
        ];
      };
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

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets.piPassword.neededForUsers = true;
  };

  users.mutableUsers = false;
  users.users.pi = {
    isNormalUser = true;
    hashedPasswordFile = config.sops.secrets.piPassword.path;
    extraGroups = [ "wheel" ];
    uid = 1000;
    openssh.authorizedKeys.keyFiles = [
      ../terra/ssh_host_ed25519_key.pub
      ../venus/ssh_host_ed25519_key.pub
    ];
  };
}
