{ config, lib, ... }:

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
    services.systemd-machine-id-commit = {
      unitConfig.ConditionPathIsMountPoint = [
        "" "/persist/state/etc/machine-id"
      ];

      serviceConfig.ExecStart = [
        "" "systemd-machine-id-setup --commit --root /persist/state"
      ];
    };
  };
}
