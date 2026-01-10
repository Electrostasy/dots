{ config, pkgs, flake, ... }:

{
  imports = [
    ../../profiles/firefox.nix
    ../../profiles/fonts.nix
    ../../profiles/gnome.nix
    ../../profiles/mpv.nix
    ../../profiles/mullvad
    ../../profiles/neovim
    ../../profiles/shell.nix
    ../../profiles/ssh.nix
    ../../profiles/tailscale.nix
    ../../users/electro
    ../luna/nfs-share.nix
    ./audio.nix
    ./gaming.nix
  ];

  nixpkgs = {
    hostPlatform.system = "x86_64-linux";
    overlays = [
      flake.outputs.overlays.qemu-unshare-fix
    ];
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    kernelPackages = pkgs.linuxPackages_latest;

    initrd = {
      systemd.root = "gpt-auto";
      luks.forceLuksSupportInInitrd = true;
      supportedFilesystems.btrfs = true;

      restoreRoot = {
        enable = true;

        device = "/dev/mapper/root";
      };

      availableKernelModules = [
        "xhci_pci"
        "ahci"
        "nvme"
        "usbhid"
        "sd_mod"
      ];
    };

    binfmt.emulatedSystems = [ "aarch64-linux" ];
  };

  programs.dconf.profiles.user.databases = [{
    settings."org/gnome/shell/extensions/tilingshell".selected-layouts = [ [ "50% Horizontal Split" "50% Vertical Split" ] ];
  }];

  environment.systemPackages = with pkgs; [
    freecad
    gimp
    kicad
    libreoffice-fresh
    picard
    prusa-slicer
  ];

  hardware = {
    cpu.intel.updateMicrocode = true;
    enableRedistributableFirmware = true;
    keyboard.qmk.enable = true;
  };

  fileSystems = {
    "/nix" = {
      device = "/dev/mapper/root";
      fsType = "btrfs";
      options = [ "subvol=nix" ];
    };

    "/persist" = {
      device = "/dev/mapper/root";
      fsType = "btrfs";
      options = [ "subvol=persist" ];
      neededForBoot = true;
    };
  };

  preservation = {
    enable = true;

    preserveAt."/persist/state".users.electro.directories = [
      ".config/FreeCAD"
      ".config/MusicBrainz"
      ".config/PrusaSlicer"
      ".config/kicad"
      ".local/share/FreeCAD"
      ".local/share/kicad"
    ];
  };

  systemd.tmpfiles.settings."10-snapper"."/persist/state/.snapshots"."v".mode = "0770";
  services.snapper = {
    persistentTimer = true;
    filters = "/nix/store";

    configs.state = {
      SUBVOLUME = "/persist/state";
      TIMELINE_CREATE = true;
      TIMELINE_CLEANUP = true;
      TIMELINE_LIMIT_MONTHLY = 0;
      TIMELINE_LIMIT_QUARTERLY = 0;
      TIMELINE_LIMIT_YEARLY = 0;
    };
  };

  networking.firewall.interfaces.${config.services.tailscale.interfaceName}.allowedTCPPorts = [ config.services.prometheus.exporters.node.port ];
  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [ "cpu.info" ];
  };

  system.stateVersion = "24.11";
}
