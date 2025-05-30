{ config, pkgs, lib, ... }:

{
  # Persist the age private key if sops-nix is used for secrets management.
  # Does not work with impermanence, as it is not mounted early enough in the
  # boot process:
  # https://github.com/Mic92/sops-nix/blob/master/README.md#setting-a-users-password
  fileSystems =
    let keyFileDir = builtins.dirOf config.sops.age.keyFile;
    in lib.mkIf (config.sops.secrets != { } && config.environment.persistence."/persist/state".enable) {
      ${keyFileDir} = {
        device = "/persist/state" + keyFileDir;
        fsType = "none";
        options = [ "bind" ];
        depends = [ "/persist/state" ];
        neededForBoot = true;
      };
    };

  # https://nixos.org/manual/nixos/unstable/#ch-system-state
  environment.persistence = {
    "/persist/cache" = {
      enable = lib.mkDefault false;

      hideMounts = true;

      users = {
        root.directories = [ ".cache/nix" ];
        electro.directories = [ ".cache/nix" ];

        # Cannot be defined from users.users due to infinite recursion.
        root.home = "/root";
      };
    };

    "/persist/state" = {
      enable = lib.mkDefault false;

      hideMounts = true;

      directories = [
        "/etc/nixos"
        "/var/lib/nixos"
        "/var/lib/systemd"
        "/var/log/journal"
      ];

      files = [ "/etc/machine-id" ];
    };
  };

  systemd = lib.mkIf config.environment.persistence."/persist/state".enable {
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
    };
  };
}
