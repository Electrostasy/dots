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
  ];

  services.xserver = {
    desktopManager.gnome.enable = true;
    displayManager.gdm = {
      enable = true;
      autoSuspend = false;
    };
  };

  # Prefer iwd to wpa_supplicant.
  networking.networkmanager.wifi.backend = lib.mkDefault "iwd";

  # Prefer pipewire to pulseaudio.
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

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
      gnome.nautilus-python
      nautilus-amberol
      nautilus-vimv

      # Thumbnailers.
      ffmpegthumbnailer

      # Graphical programs.
      amberol
      exhibit
      eyedropper
      fractal
      keepassxc
      papers
      resources
      tagger
      warp

      # CLI utilities.
      wl-clipboard
    ];
  };

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
        "org/gnome/desktop/calendar".show-weekdate = true;
        "org/gnome/desktop/input-sources".sources = [
          (mkTuple [ "xkb" "us" ])
          (mkTuple [ "xkb" "lt" ])
        ];

        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          gtk-enable-primary-paste = false;
          show-battery-percentage = true;
        };

        "org/gnome/Console" = {
          # Console seems to not be able to actually use the system font correctly,
          # but Monospace also appears to be the real system monospace font.
          use-system-font = false;
          custom-font = "Monospace 10";
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

  systemd.tmpfiles.settings."10-gnome-autostart" = {
    # Link the monitors.xml files together. This is not ideal, but GDM and
    # gnome-shell don't quite communicate on unified display settings yet.
    "/run/gdm/.config/monitors.xml"."L+".argument =
      "${config.environment.persistence.state.persistentStoragePath}/home/electro/.config/monitors.xml";

    # We need to create a directory for them first, or else we get errors
    # about unsafe path transitions from `electro` to `root` users.
    "/home/electro/.config/autostart"."d" = {
      mode = "0755";
      user = config.users.users.electro.name;
      group = config.users.users.electro.group;
    };

    # Pick a random wallpaper at startup.
    "/home/electro/.config/autostart/random-wallpaper.desktop"."L+".argument =
      let
        script = pkgs.writeShellApplication {
          name = "random-wallpaper";
          runtimeInputs = [
            pkgs.xdg-user-dirs
            pkgs.fd
          ];

          text = ''
            PICTURES="$(xdg-user-dir PICTURES)"
            FILE=$(fd '(.*\.jpeg|.*\.jpg|.*\.png)' "$PICTURES/wallpapers" | shuf -n 1)

            dconf write /org/gnome/desktop/background/picture-uri "'file://$FILE'"
            dconf write /org/gnome/desktop/background/picture-uri-dark "'file://$FILE'"
            dconf write /org/gnome/desktop/screensaver/picture-uri "'file://$FILE'"
          '';
        };
        desktopEntry = pkgs.makeDesktopItem {
          name = "random-wallpaper";
          desktopName = "Select a random wallpaper on startup";
          categories = [ "Utility" ];
          noDisplay = true;
          terminal = false;
          type = "Application";
          exec = "${script}/bin/random-wallpaper";
        };
      in
        "${desktopEntry}/share/applications/random-wallpaper.desktop";

    # Blur My Shell extension seems to be buggy regarding the panel when fractional
    # scaling is enabled - only part of the panel is blurred. Turning it on and
    # off again seems to fix it. Do that soon as the session starts.
    "/home/electro/.config/autostart/blur-my-shell-fix.desktop"."L+".argument =
      let
        script = pkgs.writeShellApplication {
          name = "blur-my-shell-fix";
          runtimeInputs = [ config.systemd.package ];

          text = ''
            service='org.gnome.Shell.Extensions'
            object='/org/gnome/Shell/Extensions'
            interface='org.gnome.Shell.Extensions'
            extension_uuid='blur-my-shell@aunetx'
            for method in DisableExtension EnableExtension; do
              busctl --user call $service $object $interface $method s $extension_uuid
              # Wait a bit before re-enabling, shorter time does not always work.
              sleep 0.5
            done
          '';
        };
        desktopEntry = pkgs.makeDesktopItem {
          name = "blur-my-shell-fix";
          desktopName = "Fix for Blur my Shell when used with fractional scaling";
          categories = [ "Utility" ];
          noDisplay = true;
          terminal = false;
          type = "Application";
          exec = "${script}/bin/blur-my-shell-fix";
        };
      in
        "${desktopEntry}/share/applications/blur-my-shell-fix.desktop";
  };
}
