{ config, pkgs, lib, ... }:

{
  preservation.preserveAt = {
    "/persist/cache" = {
      commonMountOptions = [ "x-gvfs-hide" ];

      users = {
        root = {
          home = "/root";
          directories = [ ".cache/nix" ];
        };

        electro = {
          directories = [ ".cache/nix" ];
        };
      };
    };

    "/persist/state" = {
      commonMountOptions = [ "x-gvfs-hide" ];

      directories = [
        "/etc/nixos"
        "/var/lib/nixos"
        "/var/lib/systemd"
        "/var/log/journal"
      ];

      files = [
        { file = "/etc/machine-id"; inInitrd = true; how = "symlink"; configureParent = true; }
      ];
    };
  };

  systemd = lib.mkIf config.preservation.enable {
    timers = {
      state-snapshot = {
        description = "Periodic snapshot of the /persist/state subvolume.";
        wantedBy = [ "timers.target" ];

        wants = [ "state-snapshot-enabler.service" ];
        after = [ "state-snapshot-enabler.service" ];

        timerConfig = {
          OnBootSec = "0";
          OnUnitActiveSec = "6h";
          Unit = "state-snapshot.service";
        };
      };

      state-snapshot-prune = {
        description = "Periodic prune of /persist/state subvolume snapshots.";
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
        description = "Whether to snapshot the /persist/state subvolume.";
        wantedBy = [ "multi-user.target" ];
        after = [ "local-fs.target" ];

        serviceConfig = {
          Type = "oneshot";

          ExecCondition = pkgs.writeShellScript "is-state-btrfs.sh" ''
            if ! [[ "$(stat -fc '%T' /persist/state)" == 'btrfs' ]]; then
              exit 1
            fi
          '';

          ExecStart = "${pkgs.coreutils}/bin/true";
        };
      };

      state-snapshot = {
        description = "Snapshot the /persist/state subvolume.";
        serviceConfig.Type = "oneshot";

        path = [ pkgs.btrfs-progs ];

        preStart = ''
          if [ ! -d '/persist/.snapshots' ]; then
            mkdir -p '/persist/.snapshots'
          fi
        '';

        script = ''
          btrfs subvolume snapshot -r '/persist/state' "/persist/.snapshots/state-$(date -u +%Y-%m-%dT%H:%M:%S)"
        '';
      };

      state-snapshot-prune = {
        description = "Prune the /persist/state subvolume snapshots.";
        serviceConfig.Type = "oneshot";

        path = [ pkgs.btrfs-progs ];

        script = ''
          threshold=$(date -d 'now - 3 days' +%s)
          for snapshot in /persist/.snapshots/state-*; do
            if [ $(date -d "$(basename "$snapshot")" +%s) -le $threshold ]; then
              btrfs subvolume delete "$snapshot"
            fi
          done
        '';
      };

      systemd-machine-id-commit = {
        unitConfig.ConditionPathIsMountPoint = [
          "" "/persist/state/etc/machine-id"
        ];

        serviceConfig.ExecStart = [
          "" "systemd-machine-id-setup --commit --root /persist/state"
        ];
      };
    };
  };
}
