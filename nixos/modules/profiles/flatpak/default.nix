{ config, pkgs, lib, ... }:

let
  # This cannot be made generic across all normalUsers due to a crazy infinite
  # recursion bug in Nixpkgs #24570:
  #   https://github.com/NixOS/nixpkgs/issues/24570
  # Probably won't be fixed any time soon, for now it'll be hardcoded.
  # users = builtins.attrNames
  #   (lib.filterAttrs (_: v: v.isNormalUser) config.users.users);
  users = [ "electro" ];
  mkUserModule = user: {
    services.flatpak.enable = true;
    users.users.${user}.packages = with pkgs; [ gamescope ];
    # Run steam (steamdeck beta) using:
    # $ gamescope -W 3840 -H 2160 -e -- flatpak run com.valvesoftware.Steam -gamepadui -fulldesktopres -pipewire-dmabuf
    environment.persistence."/nix/state" = {
      hideMounts = true;
      users.${user}.directories = [ ".local/share/flatpak" ".var" ];
    };
  };

in lib.mkMerge (builtins.map mkUserModule users)
