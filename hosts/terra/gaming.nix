{ config, pkgs, ... }:

let
  mkOptionsWith = extraOptions: [
    "noatime"
    "compress-force=zstd:1"
    "discard=async"
    "X-mount.owner=${config.users.users.electro.name}"
    "X-mount.group=${config.users.users.electro.group}"
    "x-gvfs-hide"
  ] ++ extraOptions;
in

{
  nixpkgs.allowUnfreePackages = [
    "steam"
    "steam-unwrapped"
  ];

  boot = {
    kernelParams = [ "vm.swappiness=10" ];
    kernelModules = [ "ntsync" ];
  };

  services.lact.enable = true;

  hardware.amdgpu.overdrive = {
    enable = true;

    ppfeaturemask = "0xFFF7FFFF"; # enables overclocking.
  };

  fileSystems = {
    "/home/electro/.local/share/Steam" = {
      device = "/dev/disk/by-label/games";
      fsType = "btrfs";
      options = mkOptionsWith [ "subvol=steam" ];
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

    "/home/electro/Games" = {
      device = "/dev/disk/by-label/games";
      fsType = "btrfs";
      options = mkOptionsWith [ "subvol=wine" ];
    };
  };

  preservation.preserveAt = {
    "/persist/cache".users.electro.directories = [
      ".cache/mesa_shader_cache"
    ];
    "/persist/state".users.electro.directories = [
      ".local/share/umu"
    ];
  };

  environment = {
    # Keep configs, state, etc. all in the same place.
    sessionVariables.DOLPHIN_EMU_USERPATH = "\${XDG_DATA_HOME:-$HOME/.local/share}/dolphin-emu";

    systemPackages = with pkgs; [
      dolphin-emu
      dualsensectl
      mangohud
      pcsx2
      umu-launcher
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
      wine
      winesync

      fps_limit=143
      fps_limit_method=early
      show_fps_limit
      vsync=0
      gl_vsync=-1
    ''}"
  ];

  programs = {
    gpu-screen-recorder.enable = true;

    steam = {
      enable = true;

      package = pkgs.steam.override {
        extraEnv = {
          PROTON_ENABLE_HDR = 1;
          PROTON_ENABLE_WAYLAND = 1;
          PROTON_USE_NTSYNC = 1;
          WAYLANDDRV_PRIMARY_MONITOR = "DP-1";
        };
      };

      protontricks.enable = true;
    };
  };

  services.ananicy = {
    enable = true;

    package = pkgs.ananicy-cpp;

    rulesProvider = pkgs.ananicy-rules-cachyos;
    extraRules = [
      # https://store.steampowered.com/app/1030840/Mafia_Definitive_Edition/
      { name = "mafiadefinitiveedition.exe"; type = "Game"; }

      # https://store.steampowered.com/app/892970/Valheim/
      { name = "valheim.exe"; type = "Game"; }
    ];
  };

  # https://gitlab.com/ananicy-cpp/ananicy-cpp/-/issues/40#note_1036996573
  systemd.services."user@".serviceConfig.Delegate = "cpu cpuset io memory pids";
}
