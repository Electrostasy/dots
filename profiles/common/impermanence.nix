{ config, pkgs, lib, ... }:

{
  users.mutableUsers = !config.environment.persistence.state.enable;

  # Persist the age private key if sops-nix is used for secrets management.
  # Does not work with impermanence, as it is not mounted early enough in the
  # boot process.
  fileSystems =
    let keyFileDir = builtins.dirOf config.sops.age.keyFile;
    in lib.mkIf (config.sops.secrets != { } && config.environment.persistence.state.enable) {
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

      # Systemd timers with `Persistent=true` set store a timestamp file with
      # the timer's last execution timestamp to disk. A persistent timer uses
      # this timestamp to measure if it needs to execute on a missed run. If
      # this is not persisted, the timer will effectively never run unless it
      # reaches the execution date again on a running system.
      "/var/lib/systemd/timers"
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

  systemd = lib.mkIf config.environment.persistence.state.enable {
    timers = {
      state-snapshot = {
        description = "Periodic snapshot of the /state subvolume.";
        wantedBy = [ "timers.target" ];

        wants = [ "state-snapshot-enabler.service" ];
        after = [ "state-snapshot-enabler.service" ];

        timerConfig = {
          OnBootSec = "0";
          OnUnitActiveSec = "3h";
          Unit = "state-snapshot.service";
        };
      };

      state-snapshot-prune = {
        description = "Periodic prune of /state subvolume snapshots.";
        wantedBy = [ "timers.target" ];

        wants = [ "state-snapshot-enabler.service" ];
        after = [ "state-snapshot-enabler.service" ];

        timerConfig = {
          OnCalendar = "weekly";
          Persistent = true;
          Unit = "state-snapshot-prune.service";
        };
      };
    };

    services = {
      # This helper service should ideally be a target unit, but they do not have
      # an execution environment, so we cannot run arbitrary code in target units.
      state-snapshot-enabler = {
        description = "Whether to snapshot the /state subvolume.";
        wantedBy = [ "multi-user.target" ];
        after = [ "local-fs.target" ];

        serviceConfig = {
          Type = "oneshot";

          ExecCondition = pkgs.writeShellScript "is-state-btrfs.sh" ''
            if ! [[ "$(stat -fc '%T' /state)" == 'btrfs' ]]; then
              exit 1
            fi
          '';

          ExecStart = "${pkgs.coreutils}/bin/true";
        };
      };

      state-snapshot = {
        description = "Snapshot the /state subvolume.";
        serviceConfig.Type = "oneshot";

        path = [ pkgs.btrfs-progs ];

        preStart = ''
          if [ ! -d '/state/.snapshots' ]; then
            mkdir -p '/state/.snapshots'
          fi
        '';

        script = ''
          btrfs subvolume snapshot -r '/state' "/state/.snapshots/$(date -u +%Y-%m-%dT%H:%M:%S)"
        '';
      };

      state-snapshot-prune = {
        description = "Prune the /state subvolume snapshots.";
        serviceConfig.Type = "oneshot";

        path = [ pkgs.btrfs-progs ];

        script = ''
          threshold=$(date -d 'now - 3 days' +%s)
          for snapshot in /state/.snapshots/*; do
            if [ $(date -d "$(basename "$snapshot")" +%s) -le $threshold ]; then
              btrfs subvolume delete "$snapshot"
            fi
          done
        '';
      };
    };
  };

}
