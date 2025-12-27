{ config, pkgs, lib, utils, ... }:

let
  cfg = config.boot.initrd.restoreRoot;
in

{
  options.boot.initrd.restoreRoot = {
    enable = lib.mkEnableOption "restoring btrfs default subvolume from a snapshot";

    device = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      description = "Device with a btrfs filesystem containing the default subvolume to restore";
      default = null;
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.device != null;
        message = "boot.initrd.restoreRoot.device cannot be null";
      }
    ];

    # https://github.com/NixOS/nixpkgs/issues/309316
    boot.initrd.systemd.storePaths = with pkgs; [
      "${btrfs-progs}/bin/btrfs"
      "${util-linux}/bin/mount"
      "${util-linux}/bin/umount"
    ];

    boot.initrd.systemd.services."restore-root-on-${utils.escapeSystemdPath cfg.device}" = {
      description = "Restore default subvolume from snapshot for btrfs filesystem on ${cfg.device}";
      wantedBy = [ "sysinit.target" ];

      after = [ "initrd-root-device.target" ];
      before = [ "local-fs-pre.target" ];

      path = [
        pkgs.btrfs-progs
        pkgs.util-linux
      ];

      unitConfig.DefaultDependencies = "no";
      serviceConfig.Type = "oneshot";

      script = ''
        if ! mount -t btrfs -o subvol=/ ${cfg.device} -m /mnt &> /dev/null; then
          echo 'ERROR: Failed to mount subvolume / to /mnt for ${cfg.device}!'
          exit 1
        fi

        trap 'umount /mnt' EXIT

        if ! btrfs subvolume get-default /mnt &> /dev/null; then
          echo 'ERROR: failed to find default subvolume on /mnt!'
          echo 'Set default subvolume with:'
          echo '# btrfs subvolume set-default /mnt/root'
          exit 1
        fi

        if ! btrfs subvolume show /mnt/root-blank &> /dev/null; then
          echo 'ERROR: failed to find snapshot at /mnt/root-blank!'
          echo 'Create a snapshot with:'
          echo '# btrfs subvolume snapshot -r /mnt/root /mnt/root-blank'
          exit 1
        fi

        if [ $? -eq 0 ]; then
          btrfs subvolume set-default /mnt
          btrfs subvolume delete -R /mnt/root
          btrfs subvolume snapshot /mnt/root-blank /mnt/root
          btrfs subvolume set-default /mnt/root
        else
          echo "ERROR: Failed to delete subvolumes under /mnt/root!"
        fi
      '';
    };
  };
}
