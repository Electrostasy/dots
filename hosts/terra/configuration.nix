{ config, pkgs, ... }:

{
  imports = [ ./gaming.nix ];

  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "22.05";

  boot = {
    initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "sd_mod" ];
    kernelModules = [ "kvm-intel" ];
    kernelPackages = pkgs.linuxPackages_latest;
    tmp = {
      useTmpfs = true;
      # Use a higher than default (50%) upper limit for /tmp to not run out of
      # space compiling programs.
      tmpfsSize = "75%";
    };
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  hardware = {
    cpu.intel.updateMicrocode = true;
    enableRedistributableFirmware = true;
  };

  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = [
        "defaults"
        "size=512M"
        "mode=755"
      ];
    };

    "/boot" = {
      device = "/dev/disk/by-label/boot";
      fsType = "vfat";
    };

    "/nix" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "btrfs";
      options = [
        "subvol=nix"
        "noatime"
        "nodiratime"
        "compress-force=zstd:1"
        "discard=async"
      ];
    };

    "/state" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "btrfs";
      options = [
        "subvol=state"
        "noatime"
        "nodiratime"
        "compress-force=zstd:1"
        "discard=async"
      ];
      neededForBoot = true;
    };
  };

  environment.persistence."/state" = {
    enable = true;

    users.electro = {
      files = [
        ".config/git-credential-keepassxc"
        ".mozilla/native-messaging-hosts/org.keepassxc.keepassxc_browser.json"
      ];

      directories = [
        ".cache"
        ".config/PrusaSlicer"
        ".config/keepassxc"
        ".local/share/fish"
        ".mozilla/firefox"
        "documents"
        "downloads"
        "pictures"
        { directory = ".ssh"; mode = "0700"; }
      ];
    };
  };

  security.rtkit.enable = true;
  services.pipewire.enable = true;

  # TODO: Fix default node setting (where did mic go?);
  # TODO: Fix default volume setting;
  # TODO: Unbreak noise suppressed microphone node from not showing in sources list.
  environment.etc = {
    "pipewire/pipewire.conf.d/60-hifiman-sundara-eq.conf".source = ./hifiman-sundara-eq.json;
    "pipewire/pipewire.conf.d/60-microphone-rnnoise.conf".source = pkgs.substitute {
      replacements = [ "--replace" "@rnnoise-plugin@" pkgs.rnnoise-plugin ];
      src = ./microphone-rnnoise.json;
    };
    "wireplumber/main.lua.d/60-disable-devices-nodes.lua".source = ./disable-device-nodes.lua;
  };

  systemd.user.services.wireplumber-default-nodes = {
    description = "PipeWire set default audio sink";
    after = [ "wireplumber.service" ];
    wantedBy = [ "graphical-session-pre.target" ];

    serviceConfig.Type = "oneshot";
    script = ''
      STATUS="$(${pkgs.wireplumber}/bin/wpctl status)"
      sink="$(echo "$STATUS" | ${pkgs.gnused}/bin/sed -n 's/[ │*]\+\([0-9]\+\)\. HIFIMAN Sundara.*/\1/p')"
      ${pkgs.wireplumber}/bin/wpctl set-default "$sink"
    '';
  };

  networking = {
    hostName = "terra";

    dhcpcd.enable = false;
    useDHCP = false;
    useNetworkd = true;
  };

  systemd.network = {
    enable = true;

    wait-online.timeout = 0;

    networks."40-wired" = {
      name = "enp*";

      DHCP = "yes";
      dns = [ "9.9.9.9" ];
    };
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;

    secrets = {
      rootPassword.neededForUsers = true;
      electroPassword.neededForUsers = true;
      sshHostKey = { };
    };
  };

  services.openssh.hostKeys = [
    { inherit (config.sops.secrets.sshHostKey) path; type = "ed25519"; }
  ];

  users = {
    mutableUsers = false;

    users = {
      # Change password using:
      # $ nix run nixpkgs#mkpasswd -- -m SHA-512 -s
      root.hashedPasswordFile = config.sops.secrets.rootPassword.path;
      electro = {
        isNormalUser = true;
        hashedPasswordFile = config.sops.secrets.electroPassword.path;
        extraGroups = [ "wheel" ];
        uid = 1000;
        openssh.authorizedKeys.keyFiles = [ ../venus/ssh_electro_ed25519_key.pub ];
      };
    };
  };
}
