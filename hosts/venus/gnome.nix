{ pkgs, ... }:

{
  # Required for ssh-askpass.
  programs.seahorse.enable = true;

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
    displayManager = {
      # https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
      # Suggested workaround (disabling "getty@tty1" and "autovt@tty1"
      # works, but as I do not use autoLogin anyway, this should suffice.
      autoLogin.enable = false;

      gdm = {
        enable = true;
        autoSuspend = false;
      };
    };
  };

  # Disable default GNOME module features.
  hardware.pulseaudio.enable = false;
  services = {
    avahi.enable = false;

    gnome = {
      core-utilities.enable = false;
      tracker-miners.enable = false;
      tracker.enable = false;
    };

    pipewire = {
      enable = true;

      pulse.enable = true;
      alsa.enable = true;
    };
  };

  # NOTE: Currently cannot connect via GUI, has to be done via iwctl.
  networking.networkmanager.wifi.backend = "iwd";

  environment = {
    gnome.excludePackages = with pkgs.gnome; [
      geary
      gnome-bluetooth
      gnome-terminal
      pkgs.gnome-tour
      pkgs.orca
    ];

    persistence."/state".users.electro = {
      # Persists multi-monitor configuration.
      files = [ ".config/monitors.xml" ];

      # TODO: Manage dconf with Nix.
      directories = [
        ".config/burn-my-windows"
        ".config/dconf"
      ];
    };

    sessionVariables.GTK_THEME = "adw-gtk3-dark";

    systemPackages = with pkgs; [
      adw-gtk3

      (nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
      recursive

      amberol
      blackbox-terminal
      celluloid
      eyedropper
      fractal-next
      gnome.cheese
      gnome.gnome-calculator
      gnome.gnome-calendar
      gnome.gnome-system-monitor
      gnome.gnome-weather
      gnome.nautilus
      gnome.sushi
      rnote
      video-trimmer
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
  };
}
