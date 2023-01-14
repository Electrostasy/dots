{ pkgs, lib, ... }:

{
  boot.kernelParams = [
    # Use faster TSC (time stamp counter) timer.
    "tsc=reliable"
    "clocksource=tsc"
  ];

  environment.etc."drirc".text = ''
    <driconf>
      <device>
        <application name="Default">
          <option name="vblank_mode" value="0" />
        </application>
      </device>
    </driconf>
  '';

  fileSystems."/home/electro/games" = {
    device = "/dev/disk/by-label/games";
    fsType = "btrfs";
    options = [ "subvol=steam" "noatime" "nodiratime" "compress-force=zstd:1" "discard=async" ];
  };

  environment.sessionVariables = {
    # Flatpak doesn't seem to be aware of its actual configuration directory.
    FLATPAK_CONFIG_DIR = "/etc/flatpak/";

    # and the .desktop files aren't detected by default in my testing.
    XDG_DATA_DIRS = [ "/home/electro/games/flatpak/exports/share" ];
  };

  # Setup a new installation directory for flatpak:
  # $ man flatpak-installation.5
  environment.etc."flatpak/installations.d/steam.conf".text = ''
    [Installation "steam"]
    Path=/home/electro/games/flatpak/
    DisplayName=Steam Games Installation
  '';

  # Override paths accessible to Steam in $FLATPAK_SYSTEM_DIR/overrides.
  systemd.tmpfiles.rules = [
    (let
      path = "/var/lib/flatpak/overrides/com.valvesoftware.Steam";
      content = builtins.replaceStrings [ "\n" ] [ "\\n" ] ''
        [Context]
        filesystems=${lib.concatMapStrings (x: x + ";") [
          # Allow Steam flatpak access to ~/.config/MangoHud outside of flatpak.
          "xdg-config/MangoHud:ro"
          # Allow Steam flatpak access to external games library.
          "/home/electro/games/SteamLibrary"
        ]}
      '';
    in "f+ ${path} 0644 root root - ${content}")

    # Tweaks for latency over throughput.
    ''
     w /proc/sys/vm/compaction_proactiveness - - - - 0
     w /proc/sys/vm/min_free_kbytes - - - - 1048576
     w /proc/sys/vm/swappiness - - - - 10
     w /proc/sys/vm/zone_reclaim_mode - - - - 0
     w /sys/kernel/mm/transparent_hugepage/enabled - - - - never
     w /sys/kernel/mm/transparent_hugepage/shmem_enabled - - - - never
     w /sys/kernel/mm/transparent_hugepage/khugepaged/defrag - - - - 0
     w /proc/sys/vm/page_lock_unfairness - - - - 1
     w /proc/sys/kernel/sched_child_runs_first - - - - 0
     w /proc/sys/kernel/sched_autogroup_enabled - - - - 1
     w /proc/sys/kernel/sched_cfs_bandwidth_slice_us - - - - 500
     w /sys/kernel/debug/sched/latency_ns  - - - - 1000000
     w /sys/kernel/debug/sched/migration_cost_ns - - - - 500000
     w /sys/kernel/debug/sched/min_granularity_ns - - - - 500000
     w /sys/kernel/debug/sched/wakeup_granularity_ns  - - - - 0
     w /sys/kernel/debug/sched/nr_migrate - - - - 8
    ''
  ];

  # $ flatpak --installation=steam remote-add flathub https://flathub.org/repo/flathub.flatpakrepo
  # $ flatpak --installation=steam install com.valvesoftware.Steam
  # $ flatpak --installation=steam install com.valvesoftware.Steam.CompatibilityTool.Proton
  # $ flatpak --installation=steam install com.valvesoftware.Steam.CompatibilityTool.Proton-Exp
  # $ flatpak --installation=steam install com.valvesoftware.Steam.CompatibilityTool.Proton-GE
  # $ flatpak --installation=steam install com.valvesoftware.Steam.Utility.gamescope
  # $ flatpak --installation=steam install org.freedesktop.Platform.VulkanLayer.Mangohud
  services.flatpak.enable = true;

  environment.persistence."/state".users.electro.directories = [
    # FIXME: Steam flatpak is basically hardcoded to this path, no success in overriding yet:
    # https://github.com/flathub/com.valvesoftware.Steam/blob/master/com.valvesoftware.Steam.yml#L62
    ".var/app/com.valvesoftware.Steam"
  ];

  home-manager.users.electro = {
    programs.mangohud = {
      enable = true;
      enableSessionWide = false;

      settings = {
        # FIXME: Font doesn't seem to be detected in flatpak.
        font_file = "${pkgs.inter}/share/fonts/opentype/Inter-Regular.otf";
        font_scale = 1.5;
        gpu_temp = true;
        cpu_temp = true;
        vram = true;
        ram = true;
        no_display = true;
        toggle_hud = "Shift_L+F12";
      };
    };
  };
}
