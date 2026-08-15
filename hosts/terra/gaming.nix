{ pkgs, ... }:

{
  nixpkgs.config.allowUnfreePackages = [
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

  preservation.preserveAt = {
    "/persist/cache".users.electro.directories = [
      ".cache/mesa_shader_cache"
    ];

    "/persist/state".users.electro.directories = [
      ".config/Mumble"
      ".config/PCSX2"
      ".local/share/Mumble"
      ".local/share/Steam"
      ".local/share/dolphin-emu"
      ".local/share/umu"
      "Games"
    ];
  };

  environment = {
    # Keep configs, state, etc. all in the same place.
    sessionVariables.DOLPHIN_EMU_USERPATH = "\${XDG_DATA_HOME:-$HOME/.local/share}/dolphin-emu";

    systemPackages = with pkgs; [
      dolphin-emu
      dualsensectl
      mangohud
      mumble
      (pcsx2.override { ffmpeg = pkgs.ffmpeg_8; }) # https://github.com/NixOS/nixpkgs/pull/552272
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

    package = pkgs.ananicy-cpp.overrideAttrs (prevAttrs: {
      # https://github.com/NixOS/nixpkgs/pull/552211
      patches = prevAttrs.patches or [] ++ [
        (pkgs.fetchurl {
          name = "0001-fix-add-missing-cstring-and-cstdint-headers-for-glibc-2-42.diff";
          url = "https://gitlab.com/ananicy-cpp/ananicy-cpp/-/merge_requests/43.diff?diff_id=1960031612";
          hash = "sha256-6J7dOunqoa8umCDW6mX28HbL/cn+aaOCcLyhgZBrVX4=";
        })
      ];
    });
    rulesProvider = pkgs.ananicy-rules-cachyos;
  };
}
