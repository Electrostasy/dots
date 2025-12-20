{ config, pkgs, lib, utils, ... }:

let
  cfg = config.boot.initrd.restore-root;
in

{
  options.boot.initrd.restore-root = {
    enable = lib.mkEnableOption "restoring btrfs subvolume from a snapshot";

    device = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      description = "Target block device";
      default = null;
    };

    to = lib.mkOption {
      type = lib.types.str;
      description = "Subvolume that will be restored to";
      default = "root";
    };

    from = lib.mkOption {
      type = lib.types.str;
      description = "Snapshot that the subvolume will be restored from";
      default = "root-blank";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.device != null;
        message = "device cannot be null";
      }
    ];

    # https://github.com/NixOS/nixpkgs/issues/309316
    boot.initrd.systemd.storePaths = with pkgs; [
      "${btrfs-progs}/bin/btrfs"
      "${util-linux}/bin/mount"
      "${util-linux}/bin/umount"
    ];

    boot.initrd.systemd.services."restore-root-on-${utils.escapeSystemdPath cfg.device}" = {
      description = "Restore from empty snapshot for impermanent btrfs device ${cfg.device}";
      wantedBy = [ "sysinit.target" ];

      after = [ "cryptsetup.target" ];
      before = [ "local-fs-pre.target" ];

      path = [
        pkgs.btrfs-progs
        pkgs.util-linux
      ];

      unitConfig.DefaultDependencies = "no";
      serviceConfig.Type = "oneshot";

      script = ''
        if ! mount -t btrfs -o subvol=/ ${cfg.device} -m /mnt &> /dev/null; then
          echo 'Error: failed to mount btrfs / subvolume to /mnt!'
          exit 1
        fi

        if ! btrfs subvolume show /mnt/${cfg.to} &> /dev/null; then
          echo 'Error: failed to find /mnt/${cfg.to} subvolume!'
          exit 1
        fi

        if ! btrfs subvolume show /mnt/${cfg.from} &> /dev/null; then
          echo 'Error: failed to find /mnt/${cfg.from} subvolume!'
          exit 1
        fi

        if [ $? -eq 0 ]; then
          btrfs subvolume set-default /mnt
          btrfs subvolume delete -R /mnt/${cfg.to}
          btrfs subvolume snapshot /mnt/${cfg.from} /mnt/${cfg.to}
          btrfs subvolume set-default /mnt/${cfg.to}
        else
          echo "Failed to delete subvolumes under /mnt/${cfg.to}!"
        fi

        umount /mnt
      '';
    };
  };
}
