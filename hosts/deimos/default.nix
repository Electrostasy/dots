{ config, pkgs, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/installer/sd-card/sd-image.nix"
    ../../profiles/minimal
    ../../profiles/shell
    ../../profiles/ssh
    ./klipper.nix
  ];

  disabledModules = [ "${modulesPath}/profiles/all-hardware.nix" ];

  nixpkgs.hostPlatform = "aarch64-linux";

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

  sdImage = {
    imageBaseName = "${config.networking.hostName}-sd-image";
    compressImage = false;

    populateFirmwareCommands = ''
      cat <<EOF > ./firmware/config.txt
      arm_64bit=1
      enable_uart=1
      avoid_warnings=1
      EOF

      cp ${pkgs.ubootRaspberryPi3_64bit}/u-boot.bin ./firmware/kernel8.img
      cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/{bootcode.bin,fixup.dat,start.elf,bcm2710-rpi-zero-2-w.dtb} ./firmware
    '';

    populateRootCommands = ''
      mkdir -p ./files/boot
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
    '';
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      # Required to enable serial console:
      # https://forums.raspberrypi.com/viewtopic.php?t=246215#p1659905
      "8250.nr_uarts=1"
      "console=ttyS0,115200"
    ];

    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

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

  systemd.network.networks."40-wireless" = {
    name = "wl*";
    DHCP = "yes";
    dns = [ "9.9.9.9" ];

    networkConfig = {
      IgnoreCarrierLoss = "yes";
      LinkLocalAddressing = "no";
    };

    dhcpV4Config = {
      Anonymize = true;
      RouteMetric = 20;
    };
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
