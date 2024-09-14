{ config, pkgs, modulesPath, self, ... }:

{
  imports = [
    "${modulesPath}/installer/sd-card/sd-image.nix"
    ../../profiles/minimal
    ../../profiles/shell
    ../../profiles/ssh
    ./nfs-server.nix
    self.inputs.nixos-hardware.nixosModules.raspberry-pi-4
  ];

  disabledModules = [ "${modulesPath}/profiles/all-hardware.nix" ];

  nixpkgs.hostPlatform = "aarch64-linux";

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

  sdImage = {
    imageBaseName = "${config.networking.hostName}-sd-image";
    compressImage = false;

    populateFirmwareCommands = ''
      cat <<EOF > ./firmware/config.txt
      armstub=armstub8-gic.bin
      enable_gic=1
      disable_overscan=1
      enable_uart=1
      avoid_warnings=1

      # If we try to access the dwc or XHCI when the firmware hasn't initialized
      # it, the system will freeze. This signals to the firmware to enable the
      # XHCI controller.
      otg_mode=1
      EOF

      cp ${pkgs.raspberrypi-armstubs}/armstub8-gic.bin ./firmware/armstub8-gic.bin
      cp ${pkgs.ubootRaspberryPi4_64bit}/u-boot.bin ./firmware/kernel8.img
      # FDT binary for the Raspberry Pi Compute Module 4 is required to boot.
      # CM4 firmware loads and modifies the device tree, and does not seem
      # capable of getting it from U-Boot.
      cp ${pkgs.raspberrypifw}/share/raspberrypi/boot/{fixup4.dat,start4.elf,bcm2711-rpi-cm4.dtb} ./firmware
    '';

    populateRootCommands = ''
      mkdir -p ./files/boot
      ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
    '';
  };

  hardware.raspberry-pi."4" = {
    # fdtoverlay can't merge some Raspberry Pi overlays (errors out with
    # FDT_ERR_NOTFOUND), as hardware.deviceTree is not RPi specific, but
    # Raspberry Pi's own dtmerge can, so this is the only way to use device
    # tree overlays on RPi in NixOS and U-Boot.
    apply-overlays-dtmerge.enable = true;

    # Required for USB to work.
    xhci.enable = true;
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;

    kernelParams = [
      "console=ttyS0,115200n8"
      "console=ttyAMA0,115200n8"
      "console=tty0"
    ];

    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  systemd.network.networks."40-wired" = {
    name = "en*";

    networkConfig = {
      DHCP = true;
      LinkLocalAddressing = false;
    };

    dhcpV4Config.RouteMetric = 10;
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

  system.stateVersion = "24.05";
}
