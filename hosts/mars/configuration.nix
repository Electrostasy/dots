{ config, pkgs, ... }:

{
  system.stateVersion = "22.05";

  boot = {
    initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "sd_mod" ];
    kernelModules = [ "kvm-intel" ];
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  hardware = {
    cpu.intel.updateMicrocode = true;
    enableRedistributableFirmware = true;
    sane.enable = true;
  };

  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = [ "defaults" "size=512M" "mode=755" ];
    };

    "/boot" = {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };

    "/nix" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "btrfs";
      options = [ "subvol=nix" "noatime" "nodiratime" "compress=zstd" "ssd" ];
    };

    "/state" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "btrfs";
      options = [ "subvol=state" "noatime" "nodiratime" "compress=zstd" "ssd" ];
      neededForBoot = true;
    };
  };

  environment.persistence."/state" = {
    hideMounts = true;
    directories = [ "/etc/nixos" "/etc/ssh" "/var/log" ];
    files = [ "/etc/machine-id" ];
    users.electro.directories = [
      ".cache"
      ".config/SchildiChat"
      { directory = ".ssh"; mode = "0700"; }
      ".mozilla"
      "Pictures"
    ];
  };

  time.timeZone = "Europe/Vilnius";
  networking = {
    hostName = "mars";
    timeServers = [
      "1.europe.pool.ntp.org"
      "1.lt.pool.ntp.org"
      "2.europe.pool.ntp.org"
    ];
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
    execWheelOnly = true;
  };

  programs.ssh.knownHosts.phobos.publicKeyFile = ../phobos/ssh_root_ed25519_key.pub;

  xdg.portal.wlr = {
    enable = true;
    settings.screencast = {
      max_fps = 30;
      chooser_type = "simple";
      chooser_cmd = "${pkgs.slurp}/bin/slurp -f %o -or";
    };
  };

  services.avahi.interfaces = [ "enp0s31f6" "enp5s0" ];

  users = {
    mutableUsers = false;
    users = {
      # Change initialHashedPassword using
      # `nix run nixpkgs#mkpasswd -- -m SHA-512 -s`
      root.initialHashedPassword = "$6$XBb5AVQUp0Mx8t.J$NkVlFCGiS8SQWHXbxImTmEBgyPJKgeqyninY18NdJaL3AVh1uCZxV.3ciZy66Pj0CAGWIobkmTp.vOqefVUgW1";
      electro = {
        isNormalUser = true;
        initialHashedPassword = "$6$MvsOwXOO9zUGCIQu$88hXJZkSR3okcpW99Xgcs77FLQAkSbCyArsagoducjN0gTY7goCZ4vN07I2zoTECdz1pHUtIVgJYWlwMnEdoY1";
        extraGroups = [ "wheel" ];
        shell = pkgs.fish;
      };
    };
  };
}
