{ config, pkgs, lib, ... }:

{
  boot = {
    kernelParams = [
      # Use faster TSC (time stamp counter) timer.
      "clocksource=tsc"
      "tsc=reliable"

      # swappiness of 10 is generally better for SSDs.
      "vm.swappiness=10"

      # Enable zswap.
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
    ];
  };

  # Not only is it useful for games, but also for programs (nix-index, compiling,
  # etc.), to have a swapfile for help with memory pressure issues.
  swapDevices = [{
    # Swapfile cannot be a bind mount such as one managed by impermanence for
    # some reason.
    device = "${config.environment.persistence.state.persistentStoragePath}/swapfile";
    size = 16 * 1024;
  }];

  environment = {
    # By default mesa shader cache is in ~/.cache/mesa_shader_cache, but can be
    # overriden by setting $MESA_SHADER_CACHE_DIR.
    persistence.state.users.electro.directories = [ ".cache/mesa_shader_cache" ];

    systemPackages = with pkgs; [ protontricks ];
  };

  users.users.electro.extraGroups = [ config.users.groups.gamemode.name ];

  programs.gamemode = {
    # `gamemoded` does not seem to be able to load `libgamemodeauto.so.0` when
    # started from within the Steam bwrap sandbox, but AFAICT it is harmless.
    enable = true;

    # Unlike `gamescope`, `gamemoded` does actually set process niceness in the
    # Steam bwrap sandbox correctly (verify with "$ ps ax -o pid,ni,cmd").
    enableRenice = true;

    settings = {
      general = {
        renice = 10;
      };

      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        amd_performance_level = "high";
      };

      custom = {
        start = builtins.toString (pkgs.writeShellScript "gamemode-start.sh" ''
          echo always > /sys/kernel/mm/transparent_hugepage/enabled
          echo 0 > /proc/sys/vm/compaction_proactiveness
          echo 0 > /sys/kernel/mm/transparent_hugepage/khugepaged/defrag
          echo 1 > /proc/sys/vm/page_lock_unfairness
        '');

        end = builtins.toString (pkgs.writeShellScript "gamemode-end.sh" ''
          echo madvise > /sys/kernel/mm/transparent_hugepage/enabled
          echo 20 > /proc/sys/vm/compaction_proactiveness
          echo 1 > /sys/kernel/mm/transparent_hugepage/khugepaged/defrag
          echo 5 > /proc/sys/vm/page_lock_unfairness
        '');
      };
    };
  };

  programs.gamescope = {
    enable = true;

    # It should be possible to add cap_sys_nice to the bwrap sandbox, but
    # every attempt I have made has made either steam not launch, or gamescope
    # not launch, so just disable it altogether.
    # Tracking issues:
    # https://github.com/NixOS/nixpkgs/issues/217119
    # https://github.com/ValveSoftware/gamescope/issues/309
    # TODO: Make the gamescope CAP_SYS_NICE wrapper run in bwrap.
    # capSysNice = true;

    args = [
      "-H 2160" # set maximum output dimensions to 3840x2160.
    ];
  };

  programs.steam = {
    enable = true;

    package = pkgs.steam-small.override {
      extraArgs = "-pipewire-dmabuf -fulldesktopres";

      extraPkgs = pkgs: with pkgs; [
        # Required for `gamescope` with Steam integration (`-e`):
        # https://github.com/NixOS/nixpkgs/issues/162562#issuecomment-1523177264
        # https://github.com/ValveSoftware/gamescope/issues/660#issuecomment-1289895009
        # Otherwise we cannot run `gamescope` in Steam in the NixOS buildFHSenv
        # bwrap sandbox.
        keyutils
        libkrb5
        libpng
        libpulseaudio
        libvorbis
        stdenv.cc.cc.lib
        xorg.libXScrnSaver
        xorg.libXcursor
        xorg.libXi
        xorg.libXinerama
      ];
    };
  };

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "steam"
    "steam-original"
    "steam-run"
  ];
}
