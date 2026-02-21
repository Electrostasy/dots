{ config, pkgs, lib, flake, ... }:

{
  nixpkgs.overlays = [
    flake.outputs.overlays.f3d-interactive
  ];

  boot = {
    loader = {
      # Show full resolution boot screen.
      systemd-boot.consoleMode = "max";

      # Hide bootloader options menu unless holding down a key.
      timeout = 0;
    };

    plymouth.enable = true;
  };

  services = {
    displayManager = {
      gdm = {
        enable = true;
        autoSuspend = false;
      };

      autoLogin = {
        enable = true;
        user = "electro";
      };
    };

    desktopManager.gnome.enable = true;

    # Use 999 for a higher priority than the default 1000.
    avahi.enable = lib.mkOverride 999 false;
    dleyna.enable = false;
    hardware.bolt.enable = false;
    gnome = {
      evolution-data-server.enable = lib.mkForce false;
      gnome-browser-connector.enable = false;
      gnome-initial-setup.enable = false;
      gnome-online-accounts.enable = lib.mkForce false;
      gnome-user-share.enable = false;
      rygel.enable = false;
    };
  };

  hardware.bluetooth.powerOnBoot = false;

  users.users.electro.extraGroups = [
    "networkmanager" # don't ask password when connecting to networks.
  ];

  security.pam.services.login.enableGnomeKeyring = true;

  xdg.terminal-exec = {
    enable = true;
    settings.GNOME = [ "com.mitchellh.ghostty.desktop" ];
  };

  preservation.preserveAt = {
    "/persist/cache".users.electro.directories = [
      ".cache/fontconfig"
      ".cache/gajim"
      ".cache/keepassxc"
      ".cache/tealdeer"
      ".cache/tracker3"

      # https://specifications.freedesktop.org/thumbnail-spec/thumbnail-spec-latest.html#DIRECTORY
      ".cache/thumbnails/fail"
      ".cache/thumbnails/large"
      ".cache/thumbnails/normal"
      ".cache/thumbnails/x-large"
      ".cache/thumbnails/xx-large"
    ];

    "/persist/state" = {
      directories = [ "/var/lib/bluetooth" ];

      users.electro = {
        files = [
          ".config/git-credential-keepassxc"
          ".config/monitors.xml"
        ];

        directories = [
          ".config/gajim"
          ".config/keepassxc"
          ".local/share/gajim"
          "Documents"
          "Downloads"
          "Music"
          "Pictures"
          "Videos"
        ];
      };
    };
  };

  environment = {
    systemPackages = with pkgs; [
      amberol
      aria2
      eyedropper
      f3d
      fd
      ffmpegthumbnailer
      file
      fractal
      freerdp
      gajim
      ghostty
      git-credential-keepassxc
      keepassxc
      libnotify
      magic-wormhole-rs
      mission-center
      nautilus-amberol
      nautilus-python
      nautilus-vimv
      ouch
      papers
      qrtool
      ripgrep
      tealdeer
      vimv-rs
      wl-clipboard

      adw-gtk3
      morewaita-icon-theme

      gnomeExtensions.blur-my-shell
      gnomeExtensions.desktop-cube
      gnomeExtensions.iso8601-ish-clock
      gnomeExtensions.system-monitor
      gnomeExtensions.tiling-shell
      gnomeExtensions.wallpaper-slideshow
    ];

    shellAliases = {
      a2c = "aria2c";
      wh = "wormhole-rs";
    };

    gnome.excludePackages = with pkgs; [
      # For xdg-* commands to work correctly on gnome, `gio` is needed, provided
      # by glib:
      # glib

      # https://gitlab.gnome.org/GNOME/gnome-shell-extensions/-/issues/512
      # For `system-monitor` shell extension to work correctly, the GNOME Core
      # program `system-monitor` is required:
      # gnome-system-monitor

      adwaita-fonts
      baobab
      decibels
      epiphany
      evince
      geary
      gnome-backgrounds
      gnome-bluetooth
      gnome-characters
      gnome-clocks
      gnome-color-manager
      gnome-connections
      gnome-console
      gnome-contacts
      gnome-font-viewer
      gnome-logs
      gnome-music
      gnome-text-editor
      gnome-themes-extra
      gnome-tour
      gnome-user-docs
      orca
      showtime
      simple-scan
      totem
      yelp
    ];
  };

  xdg.mime.defaultApplications =
    let
      associate = { desktops, mimeTypes }: lib.genAttrs mimeTypes (_: desktops);
    in
    lib.attrsets.mergeAttrsList [
      (associate {
        desktops = [ "io.bassi.Amberol.desktop" ];
        mimeTypes = [
          "audio/aac"
          "audio/ac3"
          "audio/aiff"
          "audio/flac"
          "audio/m4a"
          "audio/mp1"
          "audio/mp2"
          "audio/mp3"
          "audio/mpeg2"
          "audio/mpeg3"
          "audio/mpegurl"
          "audio/mpg"
          "audio/musepack"
          "audio/ogg"
          "audio/vnd.wave"
          "audio/vorbis"
          "audio/vorbis"
          "audio/x-wav"
        ];
      })
    ];

  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  programs.git.config.credential.helper = "${lib.getExe pkgs.git-credential-keepassxc} --git-groups";

  programs.dconf.profiles = {
    gdm.databases = [{
      settings = {
        # GDM by default is always unscaled compared to the GNOME lockscreen.
        "org/gnome/mutter".experimental-features = [ "scale-monitor-framebuffer" ];

        "org/gnome/desktop/peripherals/mouse".accel-profile = "flat";
        "org/gnome/desktop/peripherals/touchpad".tap-to-click = true;
      };
    }];

    user.databases = [{
      # Enables a way to easily reference other values in this attrset without
      # using recursive attrsets.
      settings = lib.fix (self: with lib.gvariant; {
        # Disable ^I GTK inspector warning.
        "org/gtk/gtk4/settings/debug".inspector-warning = false;

        "org/gnome/desktop/calendar".show-weekdate = true;

        "org/gnome/desktop/input-sources".sources = [
          (mkTuple [ "xkb" "us" ])
          (mkTuple [ "xkb" "lt" ])
        ];

        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          gtk-enable-primary-paste = false;
          gtk-theme = "adw-gtk3-dark";
          icon-theme = "MoreWaita";
          monospace-font-name = "Recursive 10 @MONO=1,CRSV=0,wght=400";
          show-battery-percentage = true;
        };

        "com/github/stunkymonkey/nautilus-open-any-terminal" = {
          terminal = "ghostty";
          use-generic-terminal-name = true;
        };

        "org/gnome/desktop/media-handling".automount = false;

        "org/gnome/desktop/peripherals/mouse".accel-profile = "flat";

        "org/gnome/desktop/peripherals/touchpad".tap-to-click = true;

        "org/gnome/desktop/privacy".remember-recent-files = false;

        "org/gnome/desktop/screensaver".lock-enabled = false;

        "org/gnome/desktop/session".idle-delay = mkUint32 0;

        "org/gnome/desktop/wm/preferences".resize-with-right-button = true;

        "org/gnome/mutter".experimental-features = [
          "scale-monitor-framebuffer"
          "variable-refresh-rate"
          "xwayland-native-scaling"
        ];

        "org/gnome/settings-daemon/plugins/power" = {
          power-button-action = "interactive";
          # Suspend only on battery power, not while charging.
          sleep-inactive-ac-type = "nothing";
        };

        "org/gnome/settings-daemon/plugins/housekeeping" = {
          donation-reminder-enabled = false;
        };

        "org/gnome/nautilus/preferences" = {
          date-time-format = "detailed";
          default-folder-viewer = "list-view";
        };

        "org/gnome/nautilus/list-view" = {
          default-visible-columns = [ "name" "size" "detailed_type" "date_modified" ];
          default-zoom-level = "small";
          use-tree-view = true;
        };

        "org/gtk/gtk4/settings/file-chooser" = {
          show-hidden = true;
          sort-directories-first = true;
          view-type = "list";
        };

        "org/gnome/settings-daemon/plugins/media-keys".home = [ "<Super>e" ];

        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
          binding = "<Super>Return";
          command = "/usr/bin/env ghostty +new-window";
          name = "Terminal";
        };

        # This is necessary for some reason, or the above custom-keybindings don't work.
        "org/gnome/settings-daemon/plugins/media-keys".custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
        ];

        "org/gnome/desktop/wm/keybindings" = {
          close = [ "<Shift><Super>w" ];
          move-to-workspace-left = [ "<Control><Super>a" ];
          move-to-workspace-right = [ "<Control><Super>d" ];
          panel-run-dialog = [ "<Super><Alt>space" ];
          switch-input-source = [ "<Alt>Shift_L" ]; # https://unix.stackexchange.com/a/436347
          switch-input-source-backward = mkEmptyArray type.string;
          switch-to-workspace-1 = [ "<Super>1" ];
          switch-to-workspace-2 = [ "<Super>2" ];
          switch-to-workspace-3 = [ "<Super>3" ];
          switch-to-workspace-4 = [ "<Super>4" ];
          switch-to-workspace-left = [ "<Super>a" ];
          switch-to-workspace-right = [ "<Super>d" ];
          toggle-fullscreen = [ "<Shift><Super>f" ];
          toggle-maximized = [ "<Super>f" ];
          toggle-on-all-workspaces = [ "<Control><Super>s" ];
        };

        "org/gnome/shell" = {
          enabled-extensions =
            builtins.map
              (lib.getAttr "extensionUuid")
              (lib.filter (lib.hasAttr "extensionUuid") config.environment.systemPackages);

          favorite-apps = [
            "org.keepassxc.KeePassXC.desktop"
            "org.gnome.Fractal.desktop"
            (lib.optionalString config.programs.firefox.enable "firefox.desktop")
            (lib.optionalString config.programs.steam.enable "steam.desktop")
          ];
        };

        "org/gnome/shell/keybindings" = {
          # Following binds need to be disabled, as their defaults are used for
          # the binds above, and will run into conflicts.
          switch-to-application-1 = mkEmptyArray type.string;
          switch-to-application-2 = mkEmptyArray type.string;
          switch-to-application-3 = mkEmptyArray type.string;
          switch-to-application-4 = mkEmptyArray type.string;
          toggle-application-view = mkEmptyArray type.string;
          toggle-quick-settings = mkEmptyArray type.string;

          screenshot = mkEmptyArray type.string;
          show-screen-recording-ui = [ "<Shift><Super>r" ];
          show-screenshot-ui = [ "<Shift><Super>s" ];
        };

        # Weather shown in the panel's date/notification menu.
        "org/gnome/shell/weather" = {
          automatic-location = false;

          # Locations are based on data/Locations.xml in the GNOME/libgweather repository.
          locations =
            let
              mkLocation = { name, code, latitude, longitude }:
                mkVariant (mkTuple [
                  (mkUint32 2)
                  (mkVariant (mkTuple [
                    name
                    code
                    false
                    [ (mkTuple [ latitude longitude ]) ]
                    (mkEmptyArray (with type; tupleOf [ double double ]))
                  ]))
                ]);
            in [
              (mkLocation {
                name = "Vilnius";
                code = "EYVI";
                latitude = 0.95353154218847114;
                longitude = 0.43807764225057672;
              })
            ];
        };

        # Weather shown in GNOME Weather program.
        "org/gnome/Weather".locations = self."org/gnome/shell/weather".locations;
        "org/gnome/GWeather4" = {
          distance-unit = "meters";
          speed-unit = "ms";
          temperature-unit = "centigrade";
        };

        "org/gnome/shell/extensions/desktop-cube" = {
          last-first-gap = false;
          mouse-rotation-speed = 1.0;
        };

        "org/gnome/shell/extensions/tilingshell" = {
          enable-blur-selected-tilepreview = true;
          enable-blur-snap-assistant = true;
          enable-snap-assist = false;
          enable-tiling-system-windows-suggestions = true;
          inner-gaps = mkUint32 0;
          outer-gaps = mkUint32 0;

          layouts-json = builtins.toJSON [
            {
              id = "50% Horizontal Split";
              tiles = [
                { groups = [ 1 ]; height = 1; width = 0.5; x = 0; y = 0; }
                { groups = [ 1 ]; height = 1; width = 0.5; x = 0.5; y = 0; }
              ];
            }
            {
              id = "50% Vertical Split";
              tiles = [
                { groups = [ 1 ]; height = 0.5; width = 1; x = 0; y = 0; }
                { groups = [ 1 ]; height = 0.5; width = 1; x = 0; y = 0.5; }
              ];
            }
            {
              id = "33% Horizontal Grid";
              tiles = [
                { groups = [ 1 ]; height = 1; width = 0.333333; x = 0; y = 0; }
                { groups = [ 1 ]; height = 1; width = 0.333333; x = 0.333333; y = 0; }
                { groups = [ 1 ]; height = 1; width = 0.333333; x = 0.666666; y = 0; }
              ];
            }
            {
              id = "16.67% Grid";
              tiles = [
                { groups = [ 1 4 ]; height = 0.5; width = 0.333333; x = 0; y = 0; }
                { groups = [ 2 3 1 ]; height = 0.5; width = 0.333333; x = 0.333333; y = 0; }
                { groups = [ 5 2 ]; height = 0.5; width = 0.333333; x = 0.666666; y = 0; }
                { groups = [ 3 2 1 ]; height = 0.5; width = 0.333333; x = 0.333333; y = 0.5; }
                { groups = [ 4 1 ]; height = 0.5; width = 0.333333; x = 0; y = 0.5; }
                { groups = [ 5 2 ]; height = 0.5; width = 0.333333; x = 0.666666; y = 0.5; }
              ];
            }
          ];
        };

        "org/gnome/shell/extensions/azwallpaper" = {
          slideshow-directory = "/home/electro/Pictures/wallpapers";
          slideshow-slide-duration = mkTuple (lib.map mkInt32 [ 0 30 0 ]);
          slideshow-pause = true;
        };

        "io/bassi/Amberol".background-play = false;
      });
    }];
  };

  # Normally, when dconf changes are made to the `user` profile, the user will
  # need to log out and log in again for the changes to be applied. However, in
  # NixOS, this is not sufficient for some cases (automatically enabling
  # extensions), because on a live system, the /etc/dconf path is not updated
  # to the new database on activation. This restores the intended behaviour.
  system.activationScripts.update-dconf-path = {
    text = ''
      dconf_nix_path='${config.environment.etc.dconf.source}'
      if ! [[ /etc/dconf -ef "$dconf_nix_path" ]]; then
        ln -sf "$dconf_nix_path" /etc/dconf
        dconf update /etc/dconf
      fi
    '';
  };

  # TODO: Refactor to `systemd.user.tmpfiles.settings` when
  # https://github.com/NixOS/nixpkgs/pull/317383 is merged.
  systemd.tmpfiles.settings."10-gnome-autostart" = {
    # Link the monitors.xml files together. This is not ideal, but GDM and
    # gnome-shell don't quite communicate on unified display settings yet.
    "/run/gdm/.config/monitors.xml"."L+".argument = "/persist/state/home/electro/.config/monitors.xml";
  };

  # TODO: Refactor to `systemd.user.tmpfiles.settings` when
  # https://github.com/NixOS/nixpkgs/pull/317383 is merged.
  systemd.user.tmpfiles.rules = [
    "L+ %h/.config/ghostty/themes/Poimandres - - - - ${
      (pkgs.formats.keyValue { listsAsDuplicateKeys = true; }).generate "Poimandres" {
        background = "#1b1e28";
        foreground = "#e4f0fb";
        cursor-color = "#ffffff";
        window-titlebar-background = "#171922";
        window-titlebar-foreground = "#e3f0fb";
        split-divider-color = "#506477";

        palette = [
          "0=#171922" # black
          "1=#d0679d" # red
          "2=#5fb3a1" # green
          "3=#42675a" # yellow
          "4=#7390aa" # blue
          "5=#767c9d" # magenta
          "6=#91b4d5" # cyan
          "7=#303340" # white
          "8=#506477" # brblack
          "9=#fcc5e9" # brred
          "10=#5de4c7" # brgreen
          "11=#fffac2" # bryellow
          "12=#add7ff" # brblue
          "13=#fae4fc" # brmagenta
          "14=#89ddff" # brcyan
          "15=#e4f0fb" # brwhite
        ];
      }
    }"
    "L+ %h/.config/ghostty/config - - - - ${
      (pkgs.formats.keyValue { }).generate "config" {
        font-family = "monospace"; # default to fontconfig configured monospace font.
        font-size = 10.5;
        mouse-scroll-multiplier = 1;
        shell-integration-features = "sudo,cursor,title,ssh-env";
        theme = "Poimandres";
        window-theme = "ghostty";
      }
    }"
  ];

  programs.firefox.autoConfig = ''
    pref("widget.gtk.non-native-titlebar-buttons.enabled", false);
    pref("widget.gtk.rounded-bottom-corners.enabled", true);
    pref("widget.use-xdg-desktop-portal.file-picker", 1);
  '';
}
