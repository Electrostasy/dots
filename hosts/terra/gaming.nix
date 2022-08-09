{ config, pkgs, lib, persistMount, ... }:

# For Steam Deck mode (`-gamepadui`), enter the following beta by running (native and flatpak):
# $ echo "steampal_stable_9a24a2bf68596b860cb6710d9ea307a76c29a04d" > ~/.steam/root/package/beta
# $ echo "steampal_stable_9a24a2bf68596b860cb6710d9ea307a76c29a04d" > ~/.var/app/com.valvesoftware.Steam/data/Steam/package/beta

{
  fileSystems."/home/electro/games" = {
    device = "/dev/disk/by-label/games";
    fsType = "btrfs";
    options = [ "subvol=steam" "noatime" "nodiratime" "compress-force=zstd:1" ];
  };

  environment.persistence.${persistMount} = {
    users.electro.directories = [
      # Steam
      ".local/share/Steam" ".steam"

      # Flatpak
      ".local/share/flatpak" ".var"

      # PS2 emulator
      ".config/PCSX2"
    ];
  };

  hardware.opengl.driSupport32Bit = true;

  services.flatpak.enable = true;
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
  home-manager.users.electro = {
    home.packages = with pkgs; [
      pcsx2
    ];

    programs.mangohud = {
      enable = true;
      enableSessionWide = false;

      settings = {
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

    xdg.desktopEntries = let
      gamescopeCmd = "${config.security.wrapperDir}/gamescope -w 3840 -h 2160 -r 120 -f -e";

      env = lib.concatMapStringsSep " " (x: "env ${x}") [
        # Enable mangohud for supported programs
        "MANGOHUD=1"
        # Steam will be unstable and/or crash if set to `wayland`
        "SDL_VIDEODRIVER=x11"
      ];

      # `capsh --noamb` lets gamescope run with CAP_SYS_NICE, but not propagate that
      # capability to child processes like Steam, which the nixpkgs fhsenv wrapper
      # by bwrap would otherwise complain about
      mkSteamCmd = steamBin:
        "${env} capsh --noamb -- ${steamBin} -gamepadui -fulldesktopres -pipewire-dmabuf steam://open/games";

      mkSteamDesktopEntry = { type, exec, icon }: {
        name = "Steam (${type})";
        genericName = "Steam";
        inherit exec icon;
        terminal = false;
        categories = [ "Network" "FileTransfer" "Game" ];
        mimeType = [ "x-scheme-handler/steam" "x-scheme-handler/steamlink" ];
      };
    in {
      steam = mkSteamDesktopEntry {
        type = "native";
        exec = "${gamescopeCmd} -- ${mkSteamCmd "${pkgs.steam}/bin/steam"}";
        icon = "steam";
      };

      steamFlatpak = mkSteamDesktopEntry {
        type = "flatpak";
        exec = "${gamescopeCmd} -- ${mkSteamCmd "${pkgs.flatpak}/bin/flatpak run com.valvesoftware.Steam"}";
        icon = "com.valvesoftware.Steam";
      };
    };
  };
}
