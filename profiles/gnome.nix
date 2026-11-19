{ config, pkgs, lib, ... }:

{
  boot = {
    loader = {
      systemd-boot.consoleMode = "max";
      timeout = 0;
    };

    plymouth.enable = true;
  };

  services = {
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;

    displayManager.gdm.autoSuspend = false;
    displayManager.autoLogin = {
      enable = true;
      user = "electro";
    };

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

  systemd.services."disable-wifi-on-boot" = {
    description = "Disable Wi-Fi on boot";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${config.networking.networkmanager.package}/bin/nmcli radio wifi off";
      RemainAfterExit = true;
    };
  };

  systemd.user.services."random-wallpaper" = {
    description = "Set a random wallpaper";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];

    path = [
      pkgs.coreutils-full
      pkgs.fd
      pkgs.glib
    ];

    unitConfig = {
      StartLimitIntervalSec = 0;
    };

    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writers.writeFish "random-wallpaper.fish" /* fish */ ''
        set -l wallpaper (fd --type f . "$HOME/Pictures/wallpapers" --exec-batch shuf -n 1 -e)

        if test (count $wallpaper) -eq 0
          echo 'No wallpaper found!' >&2
          exit 1
        end

        for key in picture-uri picture-uri-dark
          gsettings set org.gnome.desktop.background "$key" "file://$(string escape --style=url "$wallpaper")"
        end
      '';
      RemainAfterExit = true;
    };
  };

  security.pam.services.login.enableGnomeKeyring = true;

  preservation.preserveAt = {
    "/persist/cache".users.electro.directories = [
      ".cache/gajim"
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
          ".config/monitors.xml"
        ];

        directories = [
          ".config/gajim"
          ".config/gtk-3.0"
          ".config/keepassxc"
          ".local/share/gajim"
          ".local/share/keyrings"
          ".local/state/keepassxc"
          "Documents"
          "Downloads"
          "Music"
          "Pictures"
          "Projects"
          "Public"
          "Templates"
          "Videos"
        ];
      };
    };
  };

  environment = {
    systemPackages = with pkgs; [
      _7zz
      amberol
      aria2
      eyedropper
      f3d
      fd
      file
      freerdp
      gajim
      keepassxc
      libnotify
      magic-wormhole-rs
      nautilus-python
      nautilus-vimv
      qrtool
      ripgrep
      tealdeer
      vimv-rs
      wl-clipboard

      adw-gtk3
      morewaita-icon-theme

      gnomeExtensions.blur-my-shell
      gnomeExtensions.fullscreen-to-empty-workspace-2
      gnomeExtensions.iso8601-ish-clock
      gnomeExtensions.tiling-assistant

      # Nautilus translations do not respect LC_TIME:
      # - When LC_TIME=C, Nautilus uses %m/%d/%y %H:%M instead of %a %b %e %H:%M:%S %Y
      # - When LC_TIME=en_US.UTF-8, Nautilus uses %m/%d/%y %H:%M instead of %a %d %b %Y %r %Z
      # - When LC_TIME=en_DK.UTF-8, Nautilus uses %d/%m/%y %H.%M instead of %Y-%m-%dT%T %Z
      # - When LC_TIME=lt_LT.UTF-8, Nautilus uses %y-%m-%d %H:%M instead of %Y m. %B %d d. %T
      # Current LC_TIME is en_DK.UTF-8, closest match for nautilus is apparently lt_LT.UTF-8.
      # DBusActivatable has to be false, or else the Exec line may be ignored:
      # https://wiki.archlinux.org/title/Desktop_entries#Modify_environment_variables
      (lib.hiPrio (pkgs.runCommand "change-nautilus-LC_TIME" { } ''
        mkdir -p "$out/share/applications"
        substitute \
          ${pkgs.nautilus}/share/applications/org.gnome.Nautilus.desktop \
          "$out/share/applications/org.gnome.Nautilus.desktop" \
          --replace-fail 'DBusActivatable=true' 'DBusActivatable=false' \
          --replace-fail 'Exec=nautilus --new-window' 'Exec=/usr/bin/env LC_TIME=lt_LT.UTF-8 nautilus --new-window'
      ''))
    ];

    shellAliases = {
      a2c = "aria2c";
      wh = "wormhole-rs";
    };

    gnome.excludePackages = with pkgs; [
      adwaita-fonts
      baobab
      decibels
      epiphany
      gnome-backgrounds
      gnome-bluetooth
      gnome-characters
      gnome-clocks
      gnome-color-manager
      gnome-connections
      gnome-contacts
      gnome-font-viewer
      gnome-logs
      gnome-music
      gnome-system-monitor
      gnome-tecla
      gnome-text-editor
      gnome-tour
      gnome-user-docs
      orca
      showtime
      simple-scan
      yelp
    ];
  };

  xdg.mime.defaultApplications =
    let
      associate = { desktops, mimeTypes }: lib.genAttrs mimeTypes (_: desktops);
    in
    lib.attrsets.mergeAttrsList [
      (associate {
        # The below MIME types should not be opened by mpv.
        desktops = [ "io.bassi.Amberol.desktop" ];
        mimeTypes = [
          # The audio/x-* MIME types are seemingly irrelevant and nowadays have
          # an audio/* standardized MIME type variant that should be matched.
          "audio/aac"
          "audio/aiff"
          "audio/flac"
          "audio/mpeg"
          "audio/mpg"
          "audio/wav"
          "audio/speex"
          "audio/vorbis"
        ];
      })
      (associate {
        # The below MIME types should not be opened by prusa-slicer.
        desktops = [ "f3d.desktop" ];
        mimeTypes = [
          "model/3mf"
          "model/stl"
        ];
      })
    ];

  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  programs.git = {
    enable = true;

    package = pkgs.gitFull;

    config = {
      user = {
        name = "Gediminas Valys";
        email = "steamykins@gmail.com";
      };

      credential.helper = "${config.programs.git.package}/libexec/git-core/git-credential-libsecret";

      # Since git 2.35.2 this workaround is needed to fix an annoying error
      # when using `git` or `nixos-rebuild` as non-root in /etc/nixos:
      # fatal: detected dubious ownership in repository at '/etc/nixos'
      safe.directory = "/etc/nixos";
    };
  };

  programs.dconf.profiles = {
    gdm.databases = [{
      settings = {
        "org/gnome/desktop/peripherals/mouse".accel-profile = "flat";
      };
    }];

    user.databases = [{
      # Enables a way to easily reference other values in this attrset without
      # using recursive attrsets.
      settings = lib.fix (self: with lib.gvariant; {
        "org/gnome/desktop/input-sources".sources = [
          (mkTuple [ "xkb" "us" ])
          (mkTuple [ "xkb" "lt" ])
        ];

        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          gtk-theme = "adw-gtk3-dark";
          icon-theme = "MoreWaita";
          font-name = "Inter 11";
          document-font-name = "Inter 11";
          monospace-font-name = "Recursive 10 @MONO=1,CRSV=0,wght=400";
          show-battery-percentage = true;
        };

        "org/gnome/desktop/media-handling".automount = false;

        "org/gnome/desktop/peripherals/mouse".accel-profile = "flat";

        "org/gnome/desktop/privacy".remember-recent-files = false;

        "org/gnome/desktop/screensaver".lock-enabled = false;

        "org/gnome/desktop/session".idle-delay = mkUint32 0;

        "org/gnome/desktop/wm/preferences".resize-with-right-button = true;

        "org/gnome/mutter".experimental-features = [
          "xwayland-native-scaling"
        ];

        "org/gnome/settings-daemon/plugins/power" = {
          power-button-action = "interactive";
          sleep-inactive-ac-type = "nothing";
        };

        "org/gnome/settings-daemon/plugins/housekeeping" = {
          donation-reminder-enabled = false;
        };

        "org/gnome/nautilus/preferences" = {
          date-time-format = "detailed";
          default-folder-viewer = "list-view";
          migrated-gtk-settings = true;
        };

        "org/gnome/nautilus/list-view" = {
          default-visible-columns = [ "name" "size" "detailed_type" "date_modified" ];
          default-zoom-level = "small";
          use-tree-view = true;
        };

        "org/gtk/gtk4/settings/file-chooser" = {
          show-hidden = true;
        };

        "org/gnome/settings-daemon/plugins/media-keys".home = [ "<Super>e" ];

        "org/gnome/settings-daemon/plugins/media-keys".custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/terminal/"
        ];

        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/terminal" = {
          name = "Terminal";
          binding = "<Super>Return";
          command = "/usr/bin/env kgx";
        };

        "org/gnome/desktop/wm/keybindings" = {
          close = [ "<Shift><Super>w" ];
          move-to-workspace-left = [ "<Shift><Super>a" ];
          move-to-workspace-right = [ "<Shift><Super>d" ];
          switch-input-source = [ "<Alt>Shift_L" ]; # https://unix.stackexchange.com/a/436347
          switch-input-source-backward = mkEmptyArray type.string;
          switch-to-workspace-left = [ "<Super>a" ];
          switch-to-workspace-right = [ "<Super>d" ];
          toggle-fullscreen = [ "<Shift><Super>f" ];
          toggle-maximized = [ "<Super>f" ];
        };

        "org/gnome/shell" = {
          enabled-extensions = lib.pipe config.environment.systemPackages [
            (builtins.filter (builtins.hasAttr "extensionUuid"))
            (map (builtins.getAttr "extensionUuid"))
          ];
        };

        "org/gnome/shell/extensions/fullscreen-to-empty-workspace" = {
          move-window-when-maximized = false;
        };

        "org/gnome/shell/extensions/tiling-assistant" = {
          enable-layout-picker = false;
        };

        "org/gnome/shell/keybindings" = {
          toggle-application-view = mkEmptyArray type.string;
          screenshot = mkEmptyArray type.string;
          show-screen-recording-ui = [ "<Shift><Super>r" ];
          show-screenshot-ui = [ "<Shift><Super>s" ];
        };

        "org/gnome/shell/weather" = {
          automatic-location = false;

          # Locations are based on data/Locations.xml in the GNOME/gweather-locations repository.
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

        "org/gnome/gnome-system-monitor" = {
          network-in-bits = true;
          process-memory-in-iec = true;
          resource-memory-in-iec = true;
          show-dependencies = true;
          show-whose-processes = "all";
        };

        "io/bassi/Amberol".background-play = false;
      });
    }];
  };

  systemd.tmpfiles.settings."10-gnome-autostart" = {
    # Link the monitors.xml files together. This is not ideal, but GDM and
    # gnome-shell don't quite communicate on unified display settings yet.
    "/run/gdm/.config/monitors.xml"."L+".argument = (lib.optionalString config.preservation.enable "/persist/state") + "/home/electro/.config/monitors.xml";
  };

  programs.firefox.autoConfig = /* js */ ''
    pref("widget.gtk.non-native-titlebar-buttons.enabled", false);
    pref("widget.gtk.rounded-bottom-corners.enabled", true);
    pref("widget.use-xdg-desktop-portal.file-picker", 1);
  '';
}
