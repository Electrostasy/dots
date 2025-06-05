{ config, pkgs, lib, flake, ... }:

{
  imports = [
    ../fonts.nix
    ./debloat.nix
    ./mimetypes.nix
  ];

  nixpkgs.overlays = [ flake.overlays.f3d-interactive ];

  boot = {
    # When plymouth shows the LUKS password prompt, we may need to wait a few
    # seconds before usbhid is loaded and the keyboard functions unless we load
    # usbhid sooner.
    initrd.kernelModules = [ "usbhid" ];

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
  };

  # Required for autologin:
  # https://github.com/NixOS/nixpkgs/issues/103746
  systemd.services = {
    "getty@tty1".enable = false;
    "autovt@tty1".enable = false;
  };

  hardware.bluetooth.powerOnBoot = false;

  users.users.electro.extraGroups = [
    "networkmanager" # don't ask password when connecting to networks.
  ];

  # Log in if the user password matches the LUKS password.
  security.pam.services.login.enableGnomeKeyring = true;

  xdg.terminal-exec = {
    enable = true;
    settings.GNOME = [ "org.gnome.Ptyxis.desktop" ];
  };

  preservation.preserveAt = {
    "/persist/cache".users.electro.directories = [
      ".cache/fontconfig"
      ".cache/keepassxc"
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
        files = [ ".config/monitors.xml" ];

        directories = [
          ".config/keepassxc"
          "Documents"
          "Downloads"
          "Music"
          "Pictures"
          "Videos"
        ];
      };
    };
  };

  environment.systemPackages = with pkgs; [
    amberol
    eyedropper
    f3d
    ffmpegthumbnailer
    fractal
    freerdp
    keepassxc
    mission-center
    nautilus-amberol
    nautilus-open-any-terminal
    nautilus-python
    nautilus-vimv
    papers
    ptyxis
    wl-clipboard

    (makeAutostartItem {
      name = "random-wallpaper";
      package = makeDesktopItem {
        name = "random-wallpaper";
        desktopName = "Select a random wallpaper on startup";
        categories = [ "Utility" ];
        noDisplay = true;
        terminal = false;
        type = "Application";
        exec = lib.getExe (writeShellApplication {
          name = "random-wallpaper";
          runtimeInputs = [ xdg-user-dirs fd ];

          text = ''
            wallpaper=$(fd '(.*\.jpeg|.*\.jpg|.*\.png)' "$(xdg-user-dir PICTURES)/wallpapers" | shuf -n 1)
            for key in background/picture-uri{,-dark} screensaver/picture-uri; do
              dconf write "/org/gnome/desktop/$key" "'file://$wallpaper'"
            done
          '';
        });
      };
    })

    adw-gtk3
    morewaita-icon-theme

    gnomeExtensions.blur-my-shell
    gnomeExtensions.desktop-cube
    gnomeExtensions.iso8601-ish-clock
    gnomeExtensions.system-monitor
    gnomeExtensions.tiling-shell
    gnomeExtensions.unblank
    gnomeExtensions.user-themes
  ];

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
          terminal = "ptyxis";
          use-generic-terminal-name = true;
        };

        "org/gnome/Ptyxis/Shortcuts".close-tab = "<Shift><Control>w";

        "org/gnome/Ptyxis" = {
          default-profile-uuid = "6b79e535da7cbdbf6aaf249a66a71bb1";
          new-tab-position = "next";
          profile-uuids = [ "6b79e535da7cbdbf6aaf249a66a71bb1" ];
          restore-session = false;
        };

        "org/gnome/Ptyxis/Profiles/6b79e535da7cbdbf6aaf249a66a71bb1".palette = "poimandres";

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
          command = "/usr/bin/env ptyxis --new-window";
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

        "org/gnome/shell/extensions/user-theme".name = "electrostasy";

        "org/gnome/shell/extensions/desktop-cube" = {
          last-first-gap = false;
          mouse-rotation-speed = 1.0;
        };

        "org/gnome/shell/extensions/tilingshell" = {
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
    "L+ %h/.local/share/org.gnome.Ptyxis/palettes/poimandres.palette - - - - ${
      (pkgs.formats.ini { }).generate "poimandres.palette" {
        Palette = {
          Name = "poimandres";

          Background = "#1b1e28";
          Foreground = "#e4f0fb";
          Cursor = "#ffffff";

          Color0 = "#171922"; # #000000 "black"
          Color1 = "#d0679d"; # #800000 "red"
          Color2 = "#5fb3a1"; # #008000 "green"
          Color3 = "#42675a"; # #808000 "yellow"
          Color4 = "#7390aa"; # #000080 "blue"
          Color5 = "#767c9d"; # #800080 "magenta"
          Color6 = "#91b4d5"; # #008080 "cyan"
          Color7 = "#303340"; # #c0c0c0 "white"

          Color8 = "#506477"; # #808080 "brblack"
          Color9 = "#fcc5e9"; # #ff0000 "brred"
          Color10 = "#5de4c7"; # #00ff00 "brgreen"
          Color11 = "#fffac2"; # #ffff00 "bryellow"
          Color12 = "#add7ff"; # #0000ff "brblue"
          Color13 = "#fae4fc"; # #ff00ff "brmagenta"
          Color14 = "#89ddff"; # #00ffff "brcyan"
          Color15 = "#e4f0fb"; # #ffffff "brwhite"
        };
      }
    }"
  ];

  programs.firefox.autoConfig = ''
    pref("widget.gtk.non-native-titlebar-buttons.enabled", false);
    pref("widget.gtk.rounded-bottom-corners.enabled", true);
    pref("widget.use-xdg-desktop-portal.file-picker", 1);
  '';
}
