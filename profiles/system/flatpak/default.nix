{ pkgs, lib, persistMount, ... }:

let
  # This cannot be made generic across all normalUsers due to a crazy infinite
  # recursion bug in Nixpkgs #24570:
  #   https://github.com/NixOS/nixpkgs/issues/24570
  # Probably won't be fixed any time soon, for now it'll be hardcoded.
  # users = builtins.attrNames
  #   (lib.filterAttrs (_: v: v.isNormalUser) config.users.users);
  users = [ "electro" ];
  flatpakModule = {
    services.flatpak.enable = true;
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-wlr
      ];
    };
  };
  mkUserModule = user: {
    users.users.${user}.packages = with pkgs; [ gamescope ];
    # Run steam (steamdeck beta) using:
    # $ gamescope -W 3840 -H 2160 -e -- flatpak run com.valvesoftware.Steam -gamepadui -fulldesktopres -pipewire-dmabuf
    environment.persistence.${persistMount} = {
      hideMounts = true;
      users.${user}.directories = [ ".local/share/flatpak" ".var" ];
    };
  };

in lib.mkMerge ([ flatpakModule ] ++ (builtins.map mkUserModule users))
