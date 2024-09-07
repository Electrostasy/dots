{ config, lib, self, ... }:

let
  # Guard against tmpfs root issues, namely lack of state management. Does not
  # apply for WSL, as it does not have a NixOS defined root filesystem per the
  # wsl module.
  hasStatelessRoot = let inherit (config.fileSystems."/") device fsType;
    in !config.wsl.enable
    && device == "none"
    && fsType == "tmpfs";

  hasImpermanence = config.environment.persistence.state.enable;

  hasSops = config.sops.secrets != { };
in

{
  imports = [ self.inputs.impermanence.nixosModule ];

  warnings = lib.optionals (hasStatelessRoot && !hasImpermanence) [
    ''
      You have a root on tmpfs configuration without persistence enabled on ${config.environment.persistence.state.persistentStoragePath} for host "${config.networking.hostName}".

      This is possibly unintentional, check the option:

        environment.persistence.state.enable
    ''
  ];

  users.mutableUsers = !config.environment.persistence.state.enable;

  # Persist the age private key if sops-nix is used for secrets management.
  # Does not work with impermanence, as it is not mounted early enough in the
  # boot process.
  fileSystems =
    let keyFileDir = builtins.dirOf config.sops.age.keyFile;
    in lib.mkIf (hasSops && hasImpermanence) {
      ${keyFileDir} = {
        device = "/state" + keyFileDir;
        fsType = "none";
        options = [ "bind" ];
        depends = [ "/state" ];
        neededForBoot = true;
      };
    };

  # See section "Necessary system state" in the NixOS manual.
  environment.persistence.state = {
    # Impermanence should be opt-in by default.
    enable = lib.mkDefault false;

    persistentStoragePath = "/state";
    hideMounts = config.services.gvfs.enable;

    directories = [
      # NixOS configuration directory, used by `nixos-rebuild` etc.
      "/etc/nixos"

      # Kernel, system and other service messages/logs are stored here, which
      # can be useful to keep around between reboots.
      "/var/log"

      # NixOS uses dynamic users for systemd services wherever it can, it is
      # important to persist their UIDs and GIDs to not have corrupted state
      # on disk.
      "/var/lib/nixos"
    ]

    # On systems without a RTC (e.g. a Raspberry Pi), the clock file can be
    # crucial for startup, for e.g. DNSSEC keys cannot be validated correctly
    # if the clock is wrong.
    ++ lib.optional
      (config.services.timesyncd.enable || config.services.chrony.enable)
      # /var/lib/systemd/timesync/clock mutates, which can cause issues when
      # it is a bind mount, so we persist its parent directory instead.
      "/var/lib/systemd/timesync";

    files = [
      # This file contains the unique machine ID of the local system,
      # commonly set during installation. Programs may use this ID to identify
      # the host with a globally unique ID in the network.
      "/etc/machine-id"
    ];

    # Persist the Nix flake and evaluation caches.
    users = {
      root = {
        home = "/root";
        directories = [
          ".cache/nix"
        ];
      };

      electro.directories = [
        ".cache/nix"
      ];
    };
  };
}
