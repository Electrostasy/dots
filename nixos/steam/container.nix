{ config, pkgs, lib, ... }:

{
  # sudo nixos-container run steam -- runuser steam -c 'cd /; /run/wrappers/bin/gamescope -w 3840 -h 2160 -r 120 -e -- capsh --noamb -- steam -tenfoot -steamos -fulldesktopres'
  # https://liolok.com/containerize-steam-with-systemd-nspawn/
  # https://www.reddit.com/r/archlinux/comments/69raj1/post_your_x_wayland_systemdnspawn_examples/
  # https://nixos.wiki/wiki/Tor_Browser_in_a_Container
  containers.steam = {
    ephemeral = true;
    bindMounts = {
      "/dev/dri".isReadOnly = false;
      # "/dev/input".isReadOnly = false;
      # "/dev/shm".isReadOnly = false;
      "/home/steam/.local/share/Steam" = { hostPath = "/home/electro/hdd/steam/Steam"; isReadOnly = false; };
      "/home/steam/.steam" = { hostPath = "/home/electro/hdd/steam/.steam"; isReadOnly = false; };
      "/run/user/1000".isReadOnly = false;
    };
    allowedDevices = [
      { node = "/dev/dri"; modifier = "rwm"; }
      # { node = "/dev/shm"; modifier = "rwm"; }
      # { node = "/dev/input"; modifier = "r"; }
    ];
    config = import ./configuration.nix {
      # Use `pkgs` with package overlays applied
      inherit pkgs config lib;
    };
  };
}
