{ config, pkgs, lib, flake, ... }:

{
  # sudo nixos-container run steam -- runuser steam -c 'cd /; /run/wrappers/bin/gamescope -w 3840 -h 2160 -r 120 -e -- capsh --noamb -- steam -tenfoot -steamos -fulldesktopres'
  containers.steam = {
    ephemeral = true;
    bindMounts = {
      # Both video and render nodes are required for graphics
      "/dev/dri/card0".isReadOnly = false;
      "/dev/dri/renderD128".isReadOnly = false;
      # Bind wayland socket to run gamescope as an embedded compositor
      "/run/user/999/wayland-1" = {
        hostPath = "/run/user/1000/wayland-1";
        isReadOnly = false;
      };
      "/run/user/999/wayland-1.lock" = {
        hostPath = "/run/user/1000/wayland-1.lock";
        isReadOnly = false;
      };
    };
    allowedDevices = [
      # Minimum permissions required for graphics
      { node = "/dev/dri/card0"; modifier = "rw"; }
      { node = "/dev/dri/renderD128"; modifier = "rw"; }
      { node = "/dev/shm"; modifier = "rw"; }
    ];
    extraFlags = [ ];

    config = lib.mkMerge [
      flake.nixosModules.unfree
      (import ./gamescope.nix { inherit config pkgs lib; })
      (import ./steam.nix { inherit config pkgs lib; })
      ({ config, ... }: {
        environment.variables = {
          DISPLAY = ":1";
          WAYLAND_DISPLAY = "wayland-1";
          XDG_RUNTIME_DIR = "/run/user/999";
          XDG_SEAT = "seat0";
          XDG_SESSION_TYPE = "wayland";
        };
      })
      ({ config, ... }: {
        systemd.services.fix-run-dir-permissions = let uid = "999"; in {
          script = "chown -R gamescope:users /run/user/${uid}";
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          after = [
            "run-user-${uid}-wayland\\x2d1.mount"
            "run-user-${uid}-wayland\\x2d1.lock.mount"
          ];
          wantedBy = [ "multi-user.target" ];
        };
      })
    ];
  };
}
