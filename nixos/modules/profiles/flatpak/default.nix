{ config, pkgs, ... }:

{
  services.flatpak.enable = true;
  # Run steam (steamdeck beta) using:
  # $ gamescope -W 3840 -H 2160 -e -- flatpak run com.valvesoftware.Steam -gamepadui -fulldesktopres -pipewire-dmabuf
  environment.systemPackages = with pkgs; [ gamescope ];
  fileSystems = {
    "/home/electro/.local/share/flatpak" = {
      device = "/nix/state/home/electro/.local/share/flatpak";
      fsType = "none";
      options = [ "bind" ];
    };
    "/home/electro/.var" = {
      device = "/nix/state/home/electro/.var";
      fsType = "none";
      options = [ "bind" ];
    };
  };
}
