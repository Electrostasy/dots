{ config, pkgs, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/installer/sd-card/sd-image.nix"
    ../../profiles/system/common
    ../../profiles/system/shell
    ../../profiles/system/ssh
  ];
  disabledModules = [ "${modulesPath}/profiles/all-hardware.nix" ];

  nixpkgs.hostPlatform = "aarch64-linux";

  system.stateVersion = "23.11";

  sdImage = {
    imageBaseName = "${config.networking.hostName}-sd-image";
    compressImage = false;

    populateFirmwareCommands = /* bash */ ''
      cat <<EOF > ./firmware/config.txt
      arm_64bit=1
      enable_uart=1
      avoid_warnings=1
      EOF

      cp ${pkgs.ubootRaspberryPi3_64bit}/u-boot.bin ./firmware/kernel8.img
      cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/{bootcode.bin,fixup.dat,start.elf} ./firmware
    '';

    populateRootCommands = /* bash */ ''
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
    consoleLogLevel = 7;

    tmp.useTmpfs = true;

    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  # TODO: Setup networking properly.
  networking.hostName = "mars";

  documentation = {
    enable = false;
    man.man-db.enable = false;
  };

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

  users = {
    mutableUsers = false;
    users.pi = {
      isNormalUser = true;
      hashedPasswordFile = config.sops.secrets.piPassword.path;
      extraGroups = [ "wheel" ];
      uid = 1000;
      openssh.authorizedKeys.keyFiles = [
        ../terra/ssh_electro_ed25519_key.pub
        ../venus/ssh_electro_ed25519_key.pub
      ];
    };
  };
}