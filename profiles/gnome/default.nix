{ config, pkgs, lib, self, ... }:

{
  imports = [
    ../fonts
    ./debloat.nix
    ./extensions.nix
    ./mimetypes.nix
  ];

  nixpkgs.overlays = [
    self.overlays.f3d-assimp
    self.overlays.f3d-interactive
    self.overlays.f3d-occt

    # We need the old 5.3 version of adw-gtk3 because 5.4 only supports GNOME 47:
    # https://github.com/lassekongo83/adw-gtk3/issues/271
    # Without this downgrade, when using adw-gtk3 theme, everything has a
    # transparent background and titlebar for some reason, even gtk4 programs.
    # TODO: Remove when GNOME 47 is merged in nixpkgs:
    # https://github.com/NixOS/nixpkgs/pull/333911
    self.overlays.adw-gtk3-5_3
  ];

  xdg.terminal-exec = {
    enable = true;
    settings.GNOME = [ "org.gnome.Ptyxis.desktop" ];
  };

  services.xserver = {
    desktopManager.gnome.enable = true;
    displayManager.gdm = {
      enable = true;
      autoSuspend = false;
    };
  };

  # Do not turn on bluetooth on boot.
  hardware.bluetooth.powerOnBoot = false;

  environment = {
    persistence.state.users.electro = {
      files = [
        # Multi-monitor configuration.
        ".config/monitors.xml"
      ];

      directories = [
        ".cache/fontconfig"
        ".cache/tracker3"

        # https://specifications.freedesktop.org/thumbnail-spec/thumbnail-spec-latest.html#DIRECTORY
        ".cache/thumbnails/large"
        ".cache/thumbnails/normal"
        ".cache/thumbnails/x-large"
        ".cache/thumbnails/xx-large"
        ".cache/thumbnails/fail"

        ".cache/keepassxc"
        ".config/keepassxc"
      ];
    };

    sessionVariables.GTK_THEME = "adw-gtk3-dark";

    systemPackages = with pkgs; [
      adw-gtk3
      morewaita-icon-theme

      # Nautilus extensions.
      nautilus-python
      nautilus-amberol
      nautilus-open-any-terminal
      nautilus-vimv

      # Thumbnailers.
      ffmpegthumbnailer

      # Graphical programs.
      amberol
      exhibit
      eyedropper
      fractal
      freerdp
      keepassxc
      (makeAutostartItem { name = "org.keepassxc.KeePassXC"; package = keepassxc; })
      papers
      ptyxis
      resources
      tagger
      warp

      # CLI utilities.
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
    ];
  };

  # Normally, when dconf changes are made to the `user` profile, the user will
  # need to log out and log in again for the changes to be applied. However,
  # in NixOS, this is not sufficient for some cases (automatically enabling
  # extensions), because on a live system, the /etc/dconf path is not updated
  # to the new database on activation. This restores the intended behaviour.
  system.activationScripts.update-dconf-path.text = /* bash */ ''
    dconf_nix_path='${config.environment.etc.dconf.source}'
    if ! [[ /etc/dconf -ef "$dconf_nix_path" ]]; then
      ln -sf "$dconf_nix_path" /etc/dconf
      dconf update /etc/dconf
    fi
  '';

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
          icon-theme = "MoreWaita";
          monospace-font-name = "Recursive 10 @MONO=1,CRSV=0,wght=400";
          show-battery-percentage = true;
        };

        "com/github/stunkymonkey/nautilus-open-any-terminal" = {
          terminal = "ptyxis";
          use-generic-terminal-name = true;
        };

        "org/gnome/Ptyxis" = {
          new-tab-position = "next";
          restore-session = false;
          profile-uuids = [ "6b79e535da7cbdbf6aaf249a66a71bb1" ];
          default-profile-uuid = "6b79e535da7cbdbf6aaf249a66a71bb1";
        };

        "org/gnome/Ptyxis/Shortcuts".close-tab = "<Shift><Control>w";

        "org/gnome/Ptyxis/Profiles/6b79e535da7cbdbf6aaf249a66a71bb1" = {
          palette = lib.optionalString config.programs.neovim.enable "poimandres";
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
        ];

        "org/gnome/settings-daemon/plugins/power" = {
          power-button-action = "interactive";
          # Suspend only on battery power, not while charging.
          sleep-inactive-ac-type = "nothing";
        };

        "org/gnome/nautilus/preferences" = {
          default-folder-viewer = "list-view";
          date-time-format = "detailed";
        };

        "org/gnome/nautilus/list-view" = {
          default-zoom-level = "small";
          default-visible-columns = [ "name" "size" "detailed_type" "date_modified" ];
          use-tree-view = true;
        };

        "org/gtk/gtk4/settings/file-chooser" = {
          show-hidden = true;
          sort-directories-first = true;
          view-type = "list";
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
          command = "/usr/bin/env ptyxis --new-window";
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

        # This is necessary for some reason, or the above custom-keybindings don't work.
        "org/gnome/settings-daemon/plugins/media-keys".custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
        ];

        "org/gnome/desktop/wm/keybindings" = {
          activate-window-menu = [ "Menu" ];
          close = [ "<Shift><Super>w" ];
          move-to-workspace-left = [ "<Control><Super>a" ];
          move-to-workspace-right = [ "<Control><Super>d" ];
          toggle-on-all-workspaces = [ "<Control><Super>s" ];
          panel-run-dialog = [ "<Alt>space" ];
          switch-input-source = [ "<Alt>Shift_L" ]; # https://unix.stackexchange.com/a/436347
          switch-input-source-backward = mkEmptyArray type.string;
          switch-to-workspace-1 = [ "<Super>1" ];
          switch-to-workspace-2 = [ "<Super>2" ];
          switch-to-workspace-3 = [ "<Super>3" ];
          switch-to-workspace-4 = [ "<Super>4" ];
          switch-to-workspace-left = [ "<Shift><Super>a" ];
          switch-to-workspace-right = [ "<Shift><Super>d" ];
          toggle-fullscreen = [ "<Shift><Super>f" ];
          toggle-maximized = [ "<Super>f" ];
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
          show-screen-recording-ui = mkEmptyArray type.string;
          show-screenshot-ui = [ "<Shift><Super>s" ];
        };

        # https://www.jwestman.net/2024/02/10/new-look-for-gnome-maps.html
        "org/gnome/maps".map-type = "MapsVectorSource";

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
      });
    }];
  };

  # TODO: Refactor to `systemd.user.tmpfiles.settings` when
  # https://github.com/NixOS/nixpkgs/pull/317383 is merged.
  systemd.tmpfiles.settings."10-gnome-autostart" = {
    # Link the monitors.xml files together. This is not ideal, but GDM and
    # gnome-shell don't quite communicate on unified display settings yet.
    "/run/gdm/.config/monitors.xml"."L+".argument =
      "${config.environment.persistence.state.persistentStoragePath}/home/electro/.config/monitors.xml";
  };

  programs.firefox.autoConfig = ''
    pref("widget.gtk.rounded-bottom-corners.enabled", true);
  '';

  # TODO: Refactor to `systemd.user.tmpfiles.settings` when
  # https://github.com/NixOS/nixpkgs/pull/317383 is merged.
  systemd.user.tmpfiles.rules = [
    # Setup terminal emulator colours based on the Neovim theme.
    (lib.optionalString
      config.programs.neovim.enable
      "L+ %h/.local/share/org.gnome.Ptyxis/palettes/poimandres.palette - - - - ${
        (pkgs.formats.ini { }).generate "poimandres.palette" {
          Palette = {
            Name = "poimandres";

            Background = "#1b1e28";
            Foreground = "#e4f0fb";
            Cursor = "#ffffff";

            Color0 = "#171922"; # #000000
            Color1 = "#d0679d"; # #800000
            Color2 = "#5fb3a1"; # #008000
            Color3 = "#42675a"; # #808000
            Color4 = "#7390aa"; # #000080
            Color5 = "#767c9d"; # #800080
            Color6 = "#91b4d5"; # #008080
            Color7 = "#303340"; # #c0c0c0

            Color8 = "#506477"; # #808080
            Color9 = "#fcc5e9"; # #ff0000
            Color10 = "#5de4c7"; # #00ff00
            Color11 = "#fffac2"; # #ffff00
            Color12 = "#add7ff"; # #0000ff
            Color13 = "#fae4fc"; # #ff00ff
            Color14 = "#89ddff"; # #00ffff
            Color15 = "#e4f0fb"; # #ffffff
          };
        }
      }")
  ];

  # Setup shell colours based on the Neovim theme.
  programs.fish.interactiveShellInit = lib.optionalString config.programs.neovim.enable ''
    set -e fish_color_cancel; set -Ux fish_color_cancel d0679d --reverse
    set -e fish_color_command; set -Ux fish_color_command 89ddff
    set -e fish_color_comment; set -Ux fish_color_comment 4b4f5c
    set -e fish_color_cwd; set -Ux fish_color_cwd 5fb3a1
    set -e fish_color_end; set -Ux fish_color_end 7390aa
    set -e fish_color_error; set -Ux fish_color_error d0679d
    set -e fish_color_operator; set -Ux fish_color_operator add7ff
    set -e fish_color_param; set -Ux fish_color_param a6accd
    set -e fish_color_quote; set -Ux fish_color_quote fffac2
    set -e fish_color_redirection; set -Ux fish_color_redirection 7390aa
    set -e fish_color_valid_path; set -Ux fish_color_valid_path 5fb3a1 --underline
  '';
}
