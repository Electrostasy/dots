{ config, pkgs, lib, modulesPath, ... }:

{
  disabledModules = [ "${modulesPath}/profiles/all-hardware.nix" ];
  imports = [
    "${modulesPath}/installer/sd-card/sd-image.nix"
    "${modulesPath}/profiles/minimal.nix"
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
      armstub=armstub8-gic.bin
      enable_gic=1

      # HDMI display.
      hdmi_group=2
      hdmi_mode=87
      hdmi_cvt=1024 600 60 6 0 0 0
      disable_overscan=1

      enable_uart=1
      avoid_warnings=1
      EOF

      cp ${pkgs.raspberrypi-armstubs}/armstub8-gic.bin ./firmware/armstub8-gic.bin
      cp ${pkgs.ubootRaspberryPi4_64bit}/u-boot.bin ./firmware/kernel8.img
      # FDT binary for the Raspberry Pi 4B is required to boot. Pi 4 firmware
      # loads and modifies the device tree, and does not seem capable of
      # getting it from U-Boot.
      cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/{fixup4.dat,start4.elf,bcm2711-rpi-4-b.dtb} ./firmware
    '';

    populateRootCommands = ''
      mkdir -p ./files/boot
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
    '';
  };

  boot = {
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

  environment.systemPackages = with pkgs; [
    libgpiod
    libraspberrypi
    vim
  ];

  # Raspberry Pi 4 does not have a RTC and timesyncd is fighting with resolved
  # due to DNSSEC and expired signatures, so for now just synchronize time
  # with local network router ("DNSSEC validation failed: signature-expired").
  services.timesyncd.servers = lib.mkForce [ "192.168.205.1" ];

  networking = {
    dhcpcd.enable = false;
    useDHCP = false;
    useNetworkd = true;
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
