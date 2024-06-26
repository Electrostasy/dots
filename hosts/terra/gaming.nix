{ config, pkgs, lib, ... }:

let
  inherit (config.users.users.electro) name group;
in

{
  boot = {
    kernelParams = [
      "vm.swappiness=10"
      "zswap.enabled=1"
    ];

    # Required for zswap:
    # https://github.com/NixOS/nixpkgs/issues/44901
    initrd = {
      kernelModules = [
        "lz4hc"
        "z3fold"
      ];

      preDeviceCommands = ''
        echo lz4hc > /sys/module/zswap/parameters/compressor
        echo z3fold > /sys/module/zswap/parameters/zpool
      '';
    };
  };

  fileSystems."/home/electro/.local/share/Steam" = {
    device = "/dev/disk/by-label/games";
    fsType = "btrfs";
    options = [
      "subvol=steam"
      "noatime"
      "compress-force=zstd:1"
      "discard=async"
      "X-mount.owner=${name}"
      "X-mount.group=${group}"
    ];
  };

  environment = {
    # By default mesa shader cache is in ~/.cache/mesa_shader_cache, but can be
    # overriden by setting $MESA_SHADER_CACHE_DIR.
    persistence.state.users.electro.directories = [ ".cache/mesa_shader_cache" ];

    systemPackages = with pkgs; [
      # depotdownloader
      gpu-screen-recorder-gtk
      mangohud
    ];
  };

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "steam"
    "steam-original"
    "steam-run"
  ];

  programs = {
    steam = {
      enable = true;
      protontricks.enable = true;

      package = pkgs.steam-small.override {
        extraArgs = "-pipewire-dmabuf -fulldesktopres";
      };
    };

    gamescope = {
      enable = true;

      # https://github.com/NixOS/nixpkgs/issues/217119
      # capSysNice = true;
    };

    gamemode = {
      enable = true;
      enableRenice = true;

      settings = {
        general.renice = 10;

        custom = {
          start = builtins.toString (pkgs.writeShellScript "gamemode-start.sh" ''
            echo always > /sys/kernel/mm/transparent_hugepage/enabled
            echo 0 > /proc/sys/vm/compaction_proactiveness
            echo 0 > /sys/kernel/mm/transparent_hugepage/khugepaged/defrag
            echo 1 > /proc/sys/vm/page_lock_unfairness

            # https://gitlab.freedesktop.org/drm/amd/-/issues/1500
            echo manual > /sys/class/drm/card0/device/power_dpm_force_performance_level
            echo 1 > /sys/class/drm/card0/device/pp_power_profile_mode # 3D_FULL_SCREEN
          '');

          end = builtins.toString (pkgs.writeShellScript "gamemode-end.sh" ''
            echo madvise > /sys/kernel/mm/transparent_hugepage/enabled
            echo 20 > /proc/sys/vm/compaction_proactiveness
            echo 1 > /sys/kernel/mm/transparent_hugepage/khugepaged/defrag
            echo 5 > /proc/sys/vm/page_lock_unfairness

            # https://gitlab.freedesktop.org/drm/amd/-/issues/1500
            echo auto > /sys/class/drm/card0/device/power_dpm_force_performance_level
            echo 0 > /sys/class/drm/card0/device/pp_power_profile_mode # BOOTUP_DEFAULT
          '');
        };
      };
    };
  };

  users.users.electro.extraGroups = [ config.users.groups.gamemode.name ];
}
