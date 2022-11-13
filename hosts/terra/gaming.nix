{ pkgs, lib, ... }:

{
  fileSystems."/home/electro/games" = {
    device = "/dev/disk/by-label/games";
    fsType = "btrfs";
    options = [ "subvol=steam" "noatime" "nodiratime" "compress-force=zstd:1" ];
  };

  environment.sessionVariables = {
    # Flatpak doesn't seem to be aware of its actual configuration directory
    FLATPAK_CONFIG_DIR = "/etc/flatpak/";

    # and the .desktop files aren't detected by default in my testing
    XDG_DATA_DIRS = [ "/home/electro/games/flatpak/exports/share" ];
  };

  # Setup a new installation directory for flatpak:
  # $ man flatpak-installation.5
  environment.etc."flatpak/installations.d/steam.conf".text = ''
    [Installation "steam"]
    Path=/home/electro/games/flatpak/
    DisplayName=Steam Games Installation
  '';

  # Override paths accessible to Steam in $FLATPAK_SYSTEM_DIR/overrides
  systemd.tmpfiles.rules =
    let
      path = "/var/lib/flatpak/overrides/com.valvesoftware.Steam";
      content = builtins.replaceStrings [ "\n" ] [ "\\n" ] ''
        [Context]
        filesystems=${lib.concatMapStrings (x: x + ";") [
          # Allow Steam flatpak access to ~/.config/MangoHud outside of flatpak
          "xdg-config/MangoHud:ro"
          # Allow Steam flatpak access to external games library
          "/home/electro/games/SteamLibrary"
        ]}
      '';
    in
      [ "f+ ${path} 0644 root root - ${content}" ];

  # $ flatpak --installation=steam remote-add flathub https://flathub.org/repo/flathub.flatpakrepo
  # $ flatpak --installation=steam install com.valvesoftware.Steam
  # $ flatpak --installation=steam install com.valvesoftware.Steam.CompatibilityTool.Proton
  # $ flatpak --installation=steam install com.valvesoftware.Steam.CompatibilityTool.Proton-Exp
  # $ flatpak --installation=steam install com.valvesoftware.Steam.CompatibilityTool.Proton-GE
  # $ flatpak --installation=steam install com.valvesoftware.Steam.Utility.gamescope
  # $ flatpak --installation=steam install org.freedesktop.Platform.VulkanLayer.Mangohud
  services.flatpak.enable = true;

  users.users.electro.packages = with pkgs; [ pcsx2 ];
  environment.persistence."/state".users.electro.directories = [
    # FIXME: Steam flatpak is basically hardcoded to this path, no success in overriding yet:
    # https://github.com/flathub/com.valvesoftware.Steam/blob/master/com.valvesoftware.Steam.yml#L62
    ".var/app/com.valvesoftware.Steam"

    ".config/PCSX2"
  ];

  # NOTE: Consider only using flatpak-supplied gamescope
  security.wrappers.gamescope = {
    owner = "root";
    group = "root";
    source = "${pkgs.gamescope}/bin/gamescope";
    capabilities = "cap_sys_nice=ep";
  };

  home-manager.users.electro = {
    programs.mangohud = {
      enable = true;
      enableSessionWide = false;

      settings = {
        # FIXME: Font doesn't seem to be detected in flatpak
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
