{ config, pkgs, lib, ... }:

{
  # nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
  #   "steam"
  #   "steam-original"
  #   "steam-runtime"
  #   "steamcmd"
  # ];

  environment.variables = {
    DISPLAY = ":1";
    PULSE_SERVER = "/run/user/1000/pulse/native";
    WAYLAND_DISPLAY = "wayland-1";
    XDG_RUNTIME_DIR = "/run/user/1000";
    XDG_SEAT = "seat0";
    XDG_SESSION_TYPE = "wayland";
  };

  security.wrappers.gamescope = {
    owner = "steam";
    group = "steam";
    # Allow gamescope to re-nice itself and use realtime priority compute
    capabilities = "cap_sys_nice+pe";
    source = "${pkgs.gamescope}/bin/gamescope";
  };
  
  services.dbus.enable = true;

  nixpkgs.config.allowUnfree = true;
  programs = {
    steam.enable = true;
    gamemode.enable = true;
  };

  users.users = {
    root.initialPassword = "root";
    steam = {
      isNormalUser = true;
      initialPassword = "steam";
      extraGroups = [ "audio" "video" ];
    };
  };
}

