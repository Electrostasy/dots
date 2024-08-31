{ config, pkgs, modulesPath, ... }:

{
  disabledModules = [ "${modulesPath}/profiles/all-hardware.nix" ];
  imports = [
    "${modulesPath}/installer/sd-card/sd-image.nix"
    ../../profiles/minimal
    ../../profiles/shell
    ../../profiles/ssh
    ./klipper.nix
  ];

  nixpkgs.hostPlatform = "aarch64-linux";

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
      "console=ttyS0,115200n8"
      "console=ttyAMA0,115200n8"
      "console=tty0"
    ];

    tmp.useTmpfs = true;

    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  hardware.firmware = [ pkgs.raspberrypiWirelessFirmware ];

  networking = {
    dhcpcd.enable = false;
    useDHCP = false;
    useNetworkd = true;

    networkmanager = {
      enable = true;

      ensureProfiles = {
        environmentFiles = [ config.sops.secrets.networkmanager.path ];

        profiles.home-wifi = {
          ipv4.method = "auto";
          connection = {
            id = "Sukceno";
            type = "wifi";
            autoconnect = true;
          };
          wifi.ssid = "Sukceno";
          wifi-security = {
            auth-alg = "open";
            key-mgmt = "wpa-psk";
            psk = "$PSK_SUKCENO";
          };
        };
      };
    };
  };

  systemd.network = {
    enable = true;

    networks."40-wireless" = {
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
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      networkmanager = {};
      electroPassword.neededForUsers = true;
      electroIdentity = {
        mode = "0400";
        owner = config.users.users.electro.name;
      };
    };
  };

  users = {
    mutableUsers = false;
    users.electro = {
      isNormalUser = true;
      hashedPasswordFile = config.sops.secrets.electroPassword.path;
      extraGroups = [ "wheel" ];
      uid = 1000;
      openssh.authorizedKeys.keyFiles = [
        ../mercury/id_ed25519.pub
        ../terra/id_ed25519.pub
        ../venus/id_ed25519.pub
      ];
    };
  };

  system.stateVersion = "24.11";
}
