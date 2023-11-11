{ config, pkgs, ... }:

{
  imports = [
    ../../profiles/system/common
    ../../profiles/system/firefox
    ../../profiles/system/gnome
    ../../profiles/system/mullvad
    ../../profiles/system/shell
    ../../profiles/system/ssh
    ./gaming.nix
    ./home.nix
  ];

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

  # Tweaks CPU scheduler for responsiveness over throughput.
  programs.cfs-zen-tweaks.enable = true;

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
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  # TODO: Fix default node setting (where did mic go?);
  # TODO: Fix default volume setting;
  # TODO: Unbreak noise suppressed microphone node from not showing in sources list.
  environment.etc = let json = pkgs.formats.json { }; in {
    "pipewire/pipewire.conf.d/60-hifiman-sundara-eq.conf".source = ./hifiman-sundara-eq.json;
    "pipewire/pipewire.conf.d/60-microphone-rnnoise.conf".source = json.generate "60-microphone-rnnoise.conf" {
      context.modules = [
        {
          name = "libpipewire-module-filter-chain";
          args = {
            node.name = "Microphone w/ Noise Suppression";
            node.description = "Microphone w/ Noise Suppression";
            media.name = "Microphone w/ Noise Suppression";
            filter.graph = {
              nodes = [
                {
                  type = "ladspa";
                  name = "rnnoise";
                  plugin = "${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so";
                  label = "noise_suppressor_mono";
                  control = {
                    "VAD Threshold (%)" = 50.0;
                    "VAD Grace Period (ms)" = 200;
                    "Retroactive VAD Grace (ms)" = 0;
                  };
                }
              ];
            };
          };
          capture.props = {
            node.passive = true;
          };
          playback.props = {
            media.class = "Audio/Source";
          };
        }
      ];
    };

    "wireplumber/main.lua.d/60-disable-devices-nodes.lua".source = ./disable-device-nodes.lua;

    # Configure for low latency, fixes audio crackling.
    "pipewire/pipewire.conf.d/92-low-latency.conf".source = json.generate "92-low-latency.conf" {
      context.properties = {
        default.clock.rate = 48000;
        default.clock.quantum = 32;
        default.clock.min-quantum = 32;
        default.clock.max-quantum = 32;
      };
    };
    "pipewire/pipewire-pulse.conf.d/92-low-latency.conf".source = json.generate "92-low-latency.conf" {
      context.modules = [
        {
          name = "libpipewire-module-protocol-pulse";
          args = {
            pulse.min.req = "32/48000";
            pulse.default.req = "32/48000";
            pulse.max.req = "32/48000";
            pulse.min.quantum = "32/48000";
            pulse.max.quantum = "32/48000";
          };
        }
      ];
      stream.properties = {
        node.latency = "32/48000";
        resample.quality = 1;
      };
    };
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
