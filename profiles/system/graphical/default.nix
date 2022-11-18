{ config, pkgs, lib, ... }:

{
  environment.etc.issue =
    let
      inherit (config.system.nixos) codeName release versionSuffix;
      version = lib.removePrefix "." versionSuffix;
      mkIssue = contents: { source = pkgs.writeText "issue" contents; };
    in
      mkIssue "Welcome to NixOS ${release} (${codeName}) - ${version}\n";

  # Display a TUI login manager on the VT before starting a graphical session.
  services.greetd = {
    enable = true;
    settings.default_session.command = ''
      ${pkgs.greetd.tuigreet}/bin/tuigreet \
        --time \
        --asterisks \
        --issue \
        --remember \
        --cmd wayfire
    '';
  };

  hardware.opengl = {
    enable = true;
    driSupport = true;

    # Used for hardware accelerated video playback/encoding, without making
    # assumptions on CPU/GPU vendors. For specific Intel/AMD hardware, the
    # nixos-hardware flake modules need to be added to the configuration.
    extraPackages = with pkgs; [
      # VDPAU driver with OpenGL/VAAPI backend
      libvdpau-va-gl

      # VDPAU driver for the VAAPI library
      vaapiVdpau
    ];
  };

  # DBus is universally used as an IPC daemon in graphical desktops.
  services.dbus.enable = true;

  # Enables xdg-desktop-portal, xdg-desktop-portal-wlr (supplying Screenshot
  # and ScreenCast portals for xdg-desktop-portal and wlroots-based Wayland
  # compositors).
  xdg.portal.wlr = {
    enable = true;

    settings.screencast = {
      max_fps = 60;
      chooser_type = "simple";
      chooser_cmd = "${pkgs.slurp}/bin/slurp -f %o -or";
    };
  };
}
