{ config, pkgs, lib, ... }:

{
  fileSystems."/home/electro/games" = {
    device = "/dev/disk/by-label/games";
    fsType = "btrfs";
    options = [ "subvol=steam" "noatime" "nodiratime" "compress=zstd" "ssd" ];
  };

  environment.persistence."/state" = {
    hideMounts = true;
    users.electro.directories = [ ".local/share/Steam" ".steam" ];
  };

  hardware.opengl.driSupport32Bit = true;

  programs.steam.enable = true;
  nixpkgs.allowedUnfreePackages = with pkgs; [
    steam
    steam-run
    steamPackages.steam
    steamPackages.steam-runtime
  ];

  # Allow gamescope to re-nice itself and use realtime priority compute
  security.wrappers.gamescope = {
    owner = "root";
    group = "root";
    source = "${pkgs.gamescope}/bin/gamescope";
    capabilities = "cap_sys_nice=ep";
  };

  # TODO: Remove flatpak-supplied Steam .desktop file
  # TODO: Trap exit/shutdown somehow and instead kill gamescope?
  home-manager.users.electro = {
    programs.mangohud = {
      enable = true;
      enableSessionWide = false;

      settings = {
        font_file = "${pkgs.inter}/share/fonts/opentype/Inter-Regular.otf";
        font_scale = 1.5;
        no_display = true;
        toggle_hud = "Shift_L+F12";
      };
    };

    xdg.desktopEntries = let
      gamescopeArgs = "-w 3840 -h 2160 -r 120 -f -e";
      env = lib.concatMapStringsSep " " (x: "env ${x}") [
        "MANGOHUD=1"
        "SDL_VIDEODRIVER=x11"
      ];
      # For Steam Deck mode (`-gamepadui`), enter the following beta by running (native and flatpak):
      # $ echo "steampal_stable_9a24a2bf68596b860cb6710d9ea307a76c29a04d" > ~/.steam/root/package/beta
      # $ echo "steampal_stable_9a24a2bf68596b860cb6710d9ea307a76c29a04d" > ~/.var/app/com.valvesoftware.Steam/data/Steam/package/beta
      steamArgs = "-gamepadui -fulldesktopres -pipewire-dmabuf";

      # `capsh --noamb` lets gamescope run with CAP_SYS_NICE, but not propagate that
      # capability to child processes
      gamescopeCmd = "${config.security.wrapperDir}/gamescope ${gamescopeArgs}";
      steamCmd = "${env} capsh --noamb -- ${pkgs.steam}/bin/steam ${steamArgs}";
      steamFlatpakCmd = let
        flatpakArgs =
          "--branch=stable --arch=x86_64 --command=/app/bin/steam-wrapper";
      in "${env} capsh --noamb -- ${pkgs.flatpak}/bin/flatpak run ${flatpakArgs} com.valvesoftware.Steam ${steamArgs} steam://open/games";
    in {
      steam = {
        name = "Steam (native)";
        genericName = "Steam";
        exec = "${gamescopeCmd} -- ${steamCmd}";
        icon = "steam";
        terminal = false;
        categories = [ "Network" "FileTransfer" "Game" ];
        mimeType = [ "x-scheme-handler/steam" "x-scheme-handler/steamlink" ];
      };

      steam-flatpak = {
        name = "Steam (flatpak)";
        genericName = "Steam";
        exec = "${gamescopeCmd} -- ${steamFlatpakCmd}";
        icon = "com.valvesoftware.Steam";
        terminal = false;
        categories = [ "Network" "FileTransfer" "Game" ];
        mimeType = [ "x-scheme-handler/steam" "x-scheme-handler/steamlink" ];
      };
    };
  };
}
