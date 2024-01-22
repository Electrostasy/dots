{ config, pkgs, modulesPath, ... }:

{
  disabledModules = [ "${modulesPath}/profiles/all-hardware.nix" ];
  imports = [
    "${modulesPath}/installer/sd-card/sd-image.nix"
    ../../profiles/system/common
    ../../profiles/system/headless
    ../../profiles/system/shell
    ../../profiles/system/ssh
  ];

  nixpkgs.hostPlatform = "aarch64-linux";

  sdImage = {
    imageBaseName = "${config.networking.hostName}-sd-image";
    compressImage = false;

    populateFirmwareCommands = /* bash */ ''
      cat <<EOF > ./firmware/config.txt
      armstub=armstub8-gic.bin
      enable_gic=1
      disable_overscan=1
      enable_uart=1
      avoid_warnings=1
      EOF

      cp ${pkgs.raspberrypi-armstubs}/armstub8-gic.bin ./firmware/armstub8-gic.bin
      cp ${pkgs.ubootRaspberryPi4_64bit}/u-boot.bin ./firmware/kernel8.img
      # FDT binary for the Raspberry Pi Compute Module 4 is required to boot.
      # CM4 firmware loads and modifies the device tree, and does not seem
      # capable of getting it from U-Boot.
      cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/{fixup4.dat,start4.elf,bcm2711-rpi-cm4.dtb} ./firmware
    '';

    populateRootCommands = /* bash */ ''
      mkdir -p ./files/boot
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
    '';
  };

  boot = {
    # Required for bcachefs support until 6.7 is released.
    kernelPackages = pkgs.linuxPackages_testing;

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

  environment.systemPackages = [ pkgs.smartmontools ];

  # TODO: Add the disks once testing is done.
  # Also can't mount by UUID yet or device string:
  # https://github.com/koverstreet/bcachefs-tools/pull/142
  # fileSystems."/srv/pool" = { };

  networking = {
    dhcpcd.enable = false;
    useDHCP = false;
    useNetworkd = true;
  };

  systemd.network = {
    enable = true;

    networks."40-wired" = {
      name = "end0";

      DHCP = "yes";
      dns = [ "9.9.9.9" ];

      networkConfig.LinkLocalAddressing = "no";
      dhcpV4Config.RouteMetric = 10;
    };
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets = {
      piPassword.neededForUsers = true;
      piIdentity = {
        mode = "0400";
        owner = config.users.users.pi.name;
      };
    };
  };

  users = {
    mutableUsers = false;
    users.pi = {
      isNormalUser = true;
      hashedPasswordFile = config.sops.secrets.piPassword.path;
      extraGroups = [ "wheel" ];
      uid = 1000;
      openssh.authorizedKeys.keyFiles = [
        ../terra/ssh_host_ed25519_key.pub
        ../venus/ssh_host_ed25519_key.pub
      ];
    };
  };

  system.stateVersion = "24.05";
}
