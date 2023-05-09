{ pkgs, lib, ... }:

{
  # Use faster TSC (time stamp counter) timer.
  boot.kernelParams = [
    "tsc=reliable"
    "clocksource=tsc"
  ];

  # Disable synchronization with vertical refresh (V-Sync). Not sure if this is
  # entirely necessary on Wayland. Options described here:
  # https://dri.freedesktop.org/wiki/ConfigurationOptions/
  environment.etc."drirc".text = ''
    <driconf>
      <device>
        <application name="Default">
          <option name="vblank_mode" value="0" />
        </application>
      </device>
    </driconf>
  '';

  # Tweaks for latency over throughput.
  systemd.tmpfiles.rules = [
    "w /proc/sys/vm/compaction_proactiveness - - - - 0"
    "w /proc/sys/vm/min_free_kbytes - - - - 1048576"
    "w /proc/sys/vm/swappiness - - - - 10"
    "w /proc/sys/vm/zone_reclaim_mode - - - - 0"
    "w /sys/kernel/mm/transparent_hugepage/enabled - - - - never"
    "w /sys/kernel/mm/transparent_hugepage/shmem_enabled - - - - never"
    "w /sys/kernel/mm/transparent_hugepage/khugepaged/defrag - - - - 0"
    "w /proc/sys/vm/page_lock_unfairness - - - - 1"
    "w /proc/sys/kernel/sched_child_runs_first - - - - 0"
    "w /proc/sys/kernel/sched_autogroup_enabled - - - - 1"
    "w /proc/sys/kernel/sched_cfs_bandwidth_slice_us - - - - 500"
    "w /sys/kernel/debug/sched/latency_ns  - - - - 1000000"
    "w /sys/kernel/debug/sched/migration_cost_ns - - - - 500000"
    "w /sys/kernel/debug/sched/min_granularity_ns - - - - 500000"
    "w /sys/kernel/debug/sched/wakeup_granularity_ns  - - - - 0"
    "w /sys/kernel/debug/sched/nr_migrate - - - - 8"
  ];

  fileSystems."/home/electro/.local/share/Steam" = {
    device = "/dev/disk/by-label/games";
    fsType = "btrfs";
    options = [
      "subvol=steam"
      "noatime"
      "nodiratime"
      "compress-force=zstd:1"
      "discard=async"
    ];
  };

  environment.systemPackages = [ pkgs.gamescope ];
  programs.steam = {
    enable = true;

    package = pkgs.steam-small.override {
      extraArgs = "-pipewire-dmabuf -fulldesktopres";
    };
  };

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "steam"
    "steam-original"
    "steam-run"
  ];
}
