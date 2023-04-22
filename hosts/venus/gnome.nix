{ pkgs, ... }:

{
  # TODO: Investigate using seahorse ssh-askpass or similar for password prompts.
  programs.ssh.enableAskPassword = false;

  # Due to the way desktop configuration works in Nixpkgs, we have to install
  # an X server even if we only use Wayland.
  services.xserver = {
    enable = true;

    excludePackages = [ pkgs.xterm ] ++ (with pkgs.xorg; [
      iceauth
      xauth
      xf86inputevdev
      xinput
      xlsclients
      xorgserver
      xprop
      xrandr
      xrdb
      xset
      xsetroot
    ]);

    desktopManager.gnome.enable = true;
    displayManager.gdm = {
      enable = true;
      autoSuspend = false;
    };
  };

  # Disable default GNOME module features.
  services.avahi.enable = false;
  services.gnome = {
    core-utilities.enable = false;
    tracker-miners.enable = false;
    tracker.enable = false;
  };
  environment.gnome.excludePackages = with pkgs.gnome; [
    geary
    gnome-bluetooth
    gnome-terminal
    pkgs.gnome-tour
    pkgs.orca
  ];

  # NOTE: Currently cannot connect via GUI, has to be done via iwctl.
  networking.networkmanager.wifi.backend = "iwd";

  # Persist dconf settings.
  # TODO: Manage dconf with Nix.
  environment.persistence."/state".users.electro.directories = [
    ".config/dconf"
    ".config/burn-my-windows"
  ];

  environment.systemPackages = with pkgs; [
    (nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
    recursive

    blackbox-terminal
    celluloid
    eyedropper
    gnome.gnome-calculator
    gnome.gnome-calendar
    gnome.gnome-system-monitor
    gnome.gnome-weather
    gnome.nautilus
    gnome.sushi
    junction
    # newsflash
    rnote
    warp
  ] ++ (with pkgs.gnomeExtensions; [
    blur-my-shell
    burn-my-windows
    dash-to-panel
    date-menu-formatter
    desktop-cube
    pano
    screen-rotate
  ]);
}
