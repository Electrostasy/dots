{ pkgs, lib, ... }:

{
  imports = [ ./extensions.nix ];

  # Due to the way desktop configuration works in Nixpkgs, we have to install
  # an X server even if we only use Wayland.
  services.xserver = {
    enable = true;

    # We can exclude these packages without breaking X in gnome-shell, even if
    # I almost never use it.
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
  networking.networkmanager.wifi.backend = "iwd";
  hardware.pulseaudio.enable = false;
  services = {
    avahi.enable = false;
    pipewire = {
      enable = true;
      pulse.enable = true;
    };
  };

  environment = {
    # Most of these are optional programs added by services.gnome.core-services
    # and etc., but the module sets other useful options so it is better to
    # exclude these instead of disabling the module.
    gnome.excludePackages = with pkgs.gnome; [
      baobab # disk usage analyzer
      epiphany # web browser
      geary # e-mail client
      gnome-backgrounds
      gnome-bluetooth
      gnome-characters
      gnome-clocks
      gnome-color-manager
      gnome-contacts
      gnome-font-viewer
      gnome-logs
      gnome-music
      gnome-system-monitor
      gnome-themes-extra
      pkgs.glib
      pkgs.gnome-connections
      pkgs.gnome-photos
      pkgs.gnome-text-editor
      pkgs.gnome-tour
      pkgs.gnome-user-docs
      pkgs.orca # screen reader
      simple-scan
      totem # video player
      yelp # help viewer
    ];

    # TODO: Make independent of user.
    persistence."/state".users.electro = {
      # Multi-monitor configuration.
      files = [ ".config/monitors.xml" ];

      # GNOME file index.
      directories = [ ".cache/tracker3" ];
    };

    sessionVariables.GTK_THEME = "adw-gtk3-dark";

    systemPackages = with pkgs; [
      adw-gtk3

      (nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
      recursive

      # Load Nautilus extensions.
      gnome.nautilus-python
      nautilus-amberol
      nautilus-vimv

      amberol
      celluloid
      eartag
      eyedropper
      fractal
      keepassxc
      resources
      tagger
      warp
    ];
  };

  programs.dconf.profiles.user.databases = [{
    settings = with lib.gvariant; {
      "org/gnome/desktop/calendar".show-weekdate = true;
      "org/gnome/desktop/input-sources".sources = [
        (mkTuple [ "xkb" "us" ])
        (mkTuple [ "xkb" "lt" ])
      ];

      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        show-battery-percentage = true;
        monospace-font-name = "Recursive 11";
      };

      "org/gnome/desktop/media-handling".automount = false;
      "org/gnome/desktop/peripherals/mouse".accel-profile = "flat";
      "org/gnome/desktop/privacy".remember-recent-files = false;
      "org/gnome/desktop/screensaver".lock-enabled = false;
      "org/gnome/desktop/session".idle-delay = mkUint32 0;
      "org/gnome/desktop/wm/preferences".resize-with-right-button = true;
      "org/gnome/mutter" = {
        edge-tiling = true;
        attach-modal-dialogs = true;
        experimental-features = [ "scale-monitor-framebuffer" ];
      };

      "org/gnome/settings-daemon/plugins/power" = {
        # Suspend only on battery power, not while charging.
        sleep-inactive-ac-type = "nothing";
        power-button-action = "interactive";
      };

      "org/gnome/nautilus/preferences".default-folder-viewer = "list-view";
      "org/gnome/nautilus/list-view" = {
        use-tree-view = true;
        default-zoom-level = "small";
      };

      "org/gtk/gtk4/settings/file-chooser" = {
        sort-directories-first = true;
        show-hidden = true;
        view-type = "list";
      };

      "io/github/celluloid-player/celluloid" = {
        always-open-new-window = true;
        always-autohide-cursor = true;
        always-show-title-buttons = true;
        autofit-enable = false;
        mpv-config-enable = true;
        mpv-config-file = "file:///home/electro/.config/mpv/mpv.conf";
        mpv-input-config-enable = true;
        mpv-input-config-file = "file:///home/electro/.config/mpv/input.conf";
      };

      # Hidden/background programs only show up if they are flatpaks,
      # so disable background play for now.
      "io/bassi/Amberol".background-play = false;

      "org/gnome/settings-daemon/plugins/media-keys" = {
        screenreader = mkEmptyArray type.string;
        magnifier = mkEmptyArray type.string;
        calculator = [ "<Super>c" ];
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        binding = "<Super>Return";
        command = "/usr/bin/env kgx";
        name = "Terminal";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
        binding = "<Super>e";
        command = "/usr/bin/env nautilus";
        name = "File Manager";
      };

      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
        binding = "<Super>k";
        command = "/usr/bin/env keepassxc";
        name = "Password Manager";
      };

      "org/gnome/settings-daemon/plugins/media-keys".custom-keybindings = [
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
      ];

      "org/gnome/desktop/wm/keybindings" = {
        switch-to-workspace-left = [ "<Super>a" ];
        switch-to-workspace-right = [ "<Super>d" ];
        move-to-workspace-left = [ "<Shift><Super>a" ];
        move-to-workspace-right = [ "<Shift><Super>d" ];
        switch-to-workspace-1 = [ "<Super>1" ];
        switch-to-workspace-2 = [ "<Super>2" ];
        switch-to-workspace-3 = [ "<Super>3" ];
        switch-to-workspace-4 = [ "<Super>4" ];
        # https://unix.stackexchange.com/a/436347
        switch-input-source = [ "<Alt>Shift_L" ];
        switch-input-source-backward = mkEmptyArray type.string;
        activate-window-menu = [ "Menu" ];
        close = [ "<Shift><Super>w" ];
        maximize = [ "<Super>f" ];
        toggle-fullscreen = [ "<Shift><Super>f" ];
      };

      "org/gnome/shell/keybindings" = {
        # Following binds are replaced by the ones above.
        toggle-application-view = mkEmptyArray type.string;
        switch-to-application-1 = mkEmptyArray type.string;
        switch-to-application-2 = mkEmptyArray type.string;
        switch-to-application-3 = mkEmptyArray type.string;
        switch-to-application-4 = mkEmptyArray type.string;

        show-screen-recording-ui = mkEmptyArray type.string;
        screenshot = mkEmptyArray type.string;
        show-screenshot-ui = [ "<Shift><Super>s" ];
        screenshot-window = mkEmptyArray type.string;
      };
    };
  }];

  systemd.user.tmpfiles.rules = [
    # Automatically pick a random wallpaper at startup.
    "L+ %h/.config/autostart/wallpaper.desktop 0755 - - - ${pkgs.writeText "wallpaper.desktop" ''
      [Desktop Entry]
      Name=Wallpaper Randomiser
      Terminal=false
      Exec=${pkgs.writeShellScript "wallpaper.sh" ''
        PICTURES="$(${pkgs.xdg-user-dirs}/bin/xdg-user-dir PICTURES)"
        FILE=$(${pkgs.fd}/bin/fd '(.*\.jpeg|.*\.jpg|.*\.png)' "$PICTURES/wallpapers" | shuf -n 1)
        dconf write /org/gnome/desktop/background/picture-uri "'file://$FILE'"
        dconf write /org/gnome/desktop/background/picture-uri-dark "'file://$FILE'"
        dconf write /org/gnome/desktop/screensaver/picture-uri "'file://$FILE'"
      ''}
      Type=Application
      Categories=Utility;
      NoDisplay=true
    ''}"
  ];
}
