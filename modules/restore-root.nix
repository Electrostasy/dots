{ config, pkgs, lib, utils, ... }:

let
  cfg = config.boot.initrd.restore-root;
in

{
  options.boot.initrd.restore-root = {
    enable = lib.mkEnableOption "restoring the root filesystem from a snapshot";

    device = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      description = "Block device that will be subject to root subvolume restoration";
      default = null;
    };

    to = lib.mkOption {
      type = lib.types.str;
      description = "Name of the root subvolume that will be restored to";
      default = "root";
    };

    from = lib.mkOption {
      type = lib.types.str;
      description = "Name of the root snapshot that will be restored from";
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
      "${coreutils}/bin/cut"
      "${util-linux}/bin/mount"
      "${util-linux}/bin/umount"
    ];

    boot.initrd.systemd.services."restore-root-on-${utils.escapeSystemdPath cfg.device}" = {
      description = "Restore from empty snapshot for impermanent btrfs device ${cfg.device}";
      wantedBy = [ "sysinit.target" ];

      after = [ "cryptsetup.target" ];
      before = [ "local-fs-pre.target" ];

      path = with pkgs; [
        util-linux
        btrfs-progs
        coreutils
      ];

      unitConfig.DefaultDependencies = "no";
      serviceConfig.Type = "oneshot";

      # In order to restore the root subvolume from an empty snapshot, first
      # the lower level subvolumes under /root need to be deleted, which seem
      # to get created by systemd.
      script = ''
        mkdir /mnt
        if ! mount -t btrfs -o subvol=/ ${cfg.device} /mnt &> /dev/null; then
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

        for subvolume in $(btrfs subvolume list -o /mnt/${cfg.to} | cut -f9 -d' '); do
          btrfs subvolume delete "/mnt/$subvolume"
        done

        if [ $? -eq 0 ]; then
          btrfs subvolume delete /mnt/${cfg.to}
          btrfs subvolume snapshot /mnt/${cfg.from} /mnt/${cfg.to}
        else
          echo "Failed to delete subvolumes under /mnt/${cfg.to}!"
        fi

        umount /mnt
      '';
    };
  };
}
