{ config, pkgs, flake, ... }:

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
  nixpkgs = {
    allowUnfreePackages = [
      "steam"
      "steam-unwrapped"
    ];

    overlays = [ flake.overlays.gamescope_3_16_1 ];
  };

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

  programs = {
    gpu-screen-recorder.enable = true;

    steam = {
      enable = true;

      protontricks.enable = true;
    };

    gamescope = {
      enable = true;

      package = pkgs.gamescope_3_16_1;

      # Does not work in the Steam FHSEnv due to bubblewrap, use ananicy-cpp
      # instead: https://github.com/NixOS/nixpkgs/issues/217119
      capSysNice = false;
    };
  };

  services.ananicy = {
    enable = true;

    package = pkgs.ananicy-cpp;

    rulesProvider = pkgs.ananicy-rules-cachyos;
    extraRules = [
      # https://store.steampowered.com/app/1203620/Enshrouded/
      { name = "enshrouded.exe"; type = "Game"; }

      # https://store.steampowered.com/app/1030840/Mafia_Definitive_Edition/
      { name = "mafiadefinitiveedition.exe"; type = "Game"; }

      # https://store.steampowered.com/app/892970/Valheim/
      { name = "valheim.exe"; type = "Game"; }
    ];
  };

  # https://gitlab.com/ananicy-cpp/ananicy-cpp/-/issues/40#note_1036996573
  systemd.services."user@".serviceConfig.Delegate = "cpu cpuset io memory pids";
}
