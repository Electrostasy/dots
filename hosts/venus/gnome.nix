{ pkgs, lib, ... }:

let
  burnMyWindowsProfile = pkgs.writeText "nix-profile.conf" ''
    [burn-my-windows-profile]

    profile-high-priority=true
    profile-window-type=1
    profile-animation-type=0
    fire-enable-effect=false
    glide-enable-effect=true
    glide-animation-time=250
    glide-squish=0.0
    glide-tilt=0.0
    glide-shift=0.0
    glide-scale=0.85
  '';
in
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

    # Persists multi-monitor configuration.
    persistence."/state".users.electro.files = [ ".config/monitors.xml" ];

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
    ]);
  };

  programs.dconf.profiles = {
    # TODO: Investigate customizing gdm greeter.
    user.databases = [{
      settings = with lib.gvariant; {
        "org/gnome/desktop/interface".color-scheme = "prefer-dark";
        # TODO: This is outside of the Nix store, need to set it dynamically on shell startup.
        "org/gnome/desktop/background".picture-uri = "file:///home/electro/pictures/wallpapers/Castle Mountain, Canadian Rockies.jpeg";
        "org/gnome/desktop/background".picture-uri-dark = "file:///home/electro/pictures/wallpapers/Castle Mountain, Canadian Rockies.jpeg";
        "org/gnome/desktop/screensaver".picture-uri = "file:///home/electro/pictures/wallpapers/Castle Mountain, Canadian Rockies.jpeg";
        "org/gnome/mutter".edge-tiling = true;

        # Disable automatic screen locking.
        "org/gnome/desktop/session".idle-delay = mkUint32 0;
        "org/gnome/desktop/screensaver".lock-enabled = false;

        "org/gnome/desktop/privacy".remember-recent-files = false;

        # Suspend only on battery power, not while charging.
        "org/gnome/settings-daemon/plugins/power".sleep-inactive-ac-type = "nothing";

        "org/gnome/desktop/interface".show-battery-percentage = true;

        # Shut down when power button is pressed.
        "org/gnome/settings-daemon/plugins/power".power-button-action = "interactive";

        # Disable input device acceleration.
        "org/gnome/desktop/peripherals/mouse".accel-profile = "flat";

        "org/gnome/desktop/input-sources".sources = [
          (mkTuple [ "xkb" "us" ])
          # Add Lithuanian language.
          (mkTuple [ "xkb" "lt" ])
        ];

        # Add/remove keybindings.
        "org/gnome/settings-daemon/plugins/media-keys" = {
          screenreader = mkEmptyArray type.string;
          magnifier = mkEmptyArray type.string;
          calculator = [ "<Super>c" ];
        };

        "org/gnome/desktop/wm/keybindings" = {
          switch-to-workspace-left = [ "<Super>a" ];
          switch-to-workspace-right = [ "<Super>d" ];
          move-to-workspace-left = [ "<Shift><Super>a" ];
          move-to-workspace-right = [ "<Shift><Super>d" ];
          switch-to-workspace-1 = [ "<Super>1" ];
          switch-to-workspace-2 = [ "<Super>2" ];
          switch-to-workspace-3 = [ "<Super>3" ];
          switch-to-workspace-4 = [ "<Super>4" ];
          switch-input-source = [ "<Shift><Alt>" ];
          switch-input-source-backward = mkEmptyArray type.string;
          activate-window-menu = [ "Menu" ];
          close = [ "<Shift><Super>w" ];
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

        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
          binding = "<Super>Return";
          command = "/usr/bin/env blackbox";
          name = "Terminal";
        };

        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
          binding = "<Super>E";
          command = "/usr/bin/env nautilus";
          name = "File Manager";
        };

        "org/gnome/settings-daemon/plugins/media-keys".custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
        ];

        # Extension settings.
        "org/gnome/shell".enabled-extensions = [
          "blur-my-shell@aunetx"
          "burn-my-windows@schneegans.github.com"
          "dash-to-panel@jderose9.github.com"
          "date-menu-formatter@marcinjakubowski.github.com"
          "desktop-cube@schneegans.github.com"
        ];

        "org/gnome/shell/extensions/dash-to-panel" = {
          panel-positions = "{\"0\":\"TOP\"}";
          panel-sizes = "{\"0\":32}";
          panel-element-positions = builtins.toJSON {
            "0" = [
              { element = "showAppsButton"; visible = true; position = "stackedTL"; }
              { element = "activitiesButton"; visible = false; position = "stackedTL"; }
              { element = "dateMenu"; visible = true; position = "stackedTL"; }
              { element = "leftBox"; visible = true; position = "stackedTL"; }
              { element = "taskbar"; visible = true; position = "centerMonitor"; }
              { element = "centerBox"; visible = false; position = "centered"; }
              { element = "rightBox"; visible = true; position = "stackedBR"; }
              { element = "systemMenu"; visible = true; position = "stackedBR"; }
              { element = "desktopButton"; visible = false; position = "stackedBR"; }
            ];
          };

          show-apps-icon-file = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake-white.svg";
          show-apps-icon-padding = mkInt32 4;
          focus-highlight-dominant = true;
          dot-size = mkInt32 0;
          appicon-padding = mkInt32 2;
          appicon-margin = mkInt32 0;
          trans-use-custom-opacity = true;
          trans-panel-opacity = 0.25;
          show-favorites = false;
          group-apps = false;
          isolate-workspaces = true;
          hide-overview-on-startup = true;
          stockgs-keep-dash = true;
        };

        "org/gnome/shell/extensions/blur-my-shell".color-and-noise = false;
        "org/gnome/shell/extensions/blur-my-shell/applications".blur = false;

        # For some reason this extension does not save its settings in dconf.
        "org/gnome/shell/extensions/burn-my-windows".active-profile = "${burnMyWindowsProfile}";

        "org/gnome/shell/extensions/date-menu-formatter".pattern = "y-MM-dd kk:mm";

        "org/gnome/shell/extensions/desktop-cube" = {
          last-first-gap = false;
          window-parallax = 0.75;
          edge-switch-pressure = mkUint32 100;
          mouse-rotation-speed = 1.0;
        };

        "org/gtk/gtk4/settings/file-chooser".sort-directories-first = true;
        "org/gnome/nautilus/list-view".use-tree-view = true;

        "com/raggesilver/BlackBox".font = "Recursive Mono Casual Static 11";
      };
    }];
  };

  systemd.user.tmpfiles.rules = [
    "L+ %h/.config/burn-my-windows/profiles/nix-profile.conf 0755 - - - ${burnMyWindowsProfile}"
  ];
}
