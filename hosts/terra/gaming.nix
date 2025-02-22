{ config, pkgs, lib, ... }:

let
  mkOptionsWith = extraOptions: [
    "noatime"
    "compress-force=zstd:1"
    "discard=async"
    "X-mount.owner=${config.users.users.electro.name}"
    "X-mount.group=${config.users.users.electro.group}"
  ] ++ extraOptions;
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
        "lz4"
        "zsmalloc"
      ];

      systemd.tmpfiles.settings = {
        "10-zswap" = {
          "/sys/module/zswap/parameters/compressor".w.argument = "lz4";
          "/sys/module/zswap/parameters/zpool".w.argument = "zsmalloc";
        };

        "10-mglru-thrashing-prevention" = {
          "/sys/kernel/mm/lru_gen/enabled".w.argument = "y"; # ensure it is enabled.
          "/sys/kernel/mm/lru_gen/min_ttl_ms".w.argument = "1000";
        };
      };
    };
  };

  fileSystems = {
    "/home/electro/.local/share/Steam" = {
      device = "/dev/disk/by-label/games";
      fsType = "btrfs";
      options = mkOptionsWith [ "subvol=steam" ];
    };

    "/home/electro/.local/share/bottles" = {
      device = "/dev/disk/by-label/games";
      fsType = "btrfs";
      options = mkOptionsWith [ "subvol=bottles" ];
    };

    "/home/electro/.local/share/dolphin-emu" = {
      device = "/dev/disk/by-label/games";
      fsType = "btrfs";
      options = mkOptionsWith [ "subvol=dolphin-emu" ];
    };

    "/home/electro/.config/PCSX2" = {
      device = "/dev/disk/by-label/games";
      fsType = "btrfs";
      options = mkOptionsWith [ "subvol=pcsx2" ];
    };
  };

  environment = {
    # By default mesa shader cache is in ~/.cache/mesa_shader_cache, but can be
    # overriden by setting $MESA_SHADER_CACHE_DIR.
    persistence.state.users.electro.directories = [ ".cache/mesa_shader_cache" ];

    # Keep configs, state, etc. all in the same place.
    sessionVariables.DOLPHIN_EMU_USERPATH = "\${XDG_DATA_HOME:-$HOME/.local/share}/dolphin-emu";

    systemPackages = with pkgs; [
      bottles
      dolphin-emu
      dualsensectl
      mangohud
      pcsx2
    ];
  };

  # TODO: Convert to dedicated MangoHud NixOS module.
  # TODO: Refactor to `systemd.user.tmpfiles.settings` when
  # https://github.com/NixOS/nixpkgs/pull/317383 is merged.
  systemd.user.tmpfiles.rules = [
    "L+ %h/.config/MangoHud/MangoHud.conf - - - - ${pkgs.writeText "MangoHud.conf" ''
      toggle_hud=F12
      fps_color_change
      frame_timing
      cpu_load_change
      cpu_temp
      gpu_junction_temp
      gpu_load_change
      gpu_temp
      ram
      vram
      swap
      graphs=gpu_load,cpu_load
      histogram
      throttling_status_graph
    ''}"
  ];

  nixpkgs.allowUnfreePackages = [
    "steam"
    "steam-unwrapped"
  ];

  programs = {
    gpu-screen-recorder.enable = true;

    steam = {
      enable = true;

      protontricks.enable = true;
    };

    gamescope = {
      enable = true;

      # Fix frametime issues that appear after 15-30 min. playtime for resource
      # intensive games:
      # https://github.com/ValveSoftware/gamescope/issues/163
      # https://github.com/ValveSoftware/gamescope/issues/697#issuecomment-2564875728
      env.LD_PRELOAD = "''";
      args = lib.mkAfter [ "env LD_PRELOAD=$LD_PRELOAD" ];

      # https://github.com/NixOS/nixpkgs/issues/217119
      capSysNice = false;
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
