{ pkgs, lib, ... }:

{
  imports = [
    ./debloat.nix
    ./extensions.nix
    ./mimetypes.nix
  ];

  services.xserver = {
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

  # Prefer iwd to wpa_supplicant.
  networking.networkmanager.wifi.backend = "iwd";

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

      # Load Nautilus extensions.
      gnome.nautilus-python
      nautilus-amberol
      nautilus-vimv

      # Thumbnailers.
      ffmpegthumbnailer

      # Extra programs to install.
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

  systemd.user.tmpfiles.rules = [
    # Pick a random wallpaper at startup.
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

  fonts = {
    enableDefaultPackages = false;

    # Override default GNOME fonts.
    packages = with pkgs; lib.mkForce [
      (nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
      inter
      ipaexfont
      liberation_ttf
      recursive
      twemoji-color-font
    ];

    fontconfig = {
      defaultFonts = {
        monospace = [
          "Recursive Mn Lnr St"
          "Symbols Nerd Font Mono"
        ];
        sansSerif = [
          "Inter"
          "Liberation Sans"
          "IPAexGothic"
        ];
        serif = [
          "Liberation Serif"
          "IPAexMincho"
        ];
        emoji = [
          "Twitter Color Emoji SVGinOT"
        ];
      };

      localConf = /* xml */ ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
        <fontconfig>
          <match target="font">
            <test qual="any" name="family"><string>Inter</string></test>
            <!-- https://rsms.me/inter/#features -->
            <edit name="fontfeatures" mode="prepend">
              <!-- Contextural alternatives -->
              <string>calt off</string>
              <!-- Tabular numbers -->
              <string>tnum</string>
              <!-- Case alternates -->
              <string>case</string>
              <!-- Compositions -->
              <string>ccmp off</string>
              <!-- Disambiguation -->
              <string>ss02</string>
            </edit>
          </match>
          <match target="font">
            <test qual="any" name="family"><string>Recursive</string></test>
            <!-- https://github.com/arrowtype/recursive#opentype-features -->
            <edit name="fontfeatures" mode="prepend">
              <!-- Code ligatures -->
              <string>dlig off</string>
              <!-- Single-story 'a' -->
              <string>ss01</string>
              <!-- Single-story 'g' -->
              <string>ss02</string>
              <!-- Simplified mono 'at' -->
              <string>ss12</string>
              <!-- Uppercase punctuation -->
              <string>case</string>
              <!-- Slashed zero -->
              <string>ss20</string>
            </edit>
          </match>
        </fontconfig>
      '';
    };
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
      };

      # Console seems to not be able to actually use the system font correctly,
      # but Monospace also appears to be the real system monospace font.
      "org/gnome/Console" = {
        use-system-font = false;
        custom-font = "Monospace 10";
      };

      "org/gnome/desktop/media-handling".automount = false;
      "org/gnome/desktop/peripherals/mouse".accel-profile = "flat";
      "org/gnome/desktop/privacy".remember-recent-files = false;
      "org/gnome/desktop/screensaver".lock-enabled = false;
      "org/gnome/desktop/session".idle-delay = mkUint32 0;
      "org/gnome/desktop/wm/preferences".resize-with-right-button = true;
      "org/gnome/mutter".experimental-features = [ "scale-monitor-framebuffer" ];

      "org/gnome/settings-daemon/plugins/power" = {
        power-button-action = "interactive";
        # Suspend only on battery power, not while charging.
        sleep-inactive-ac-type = "nothing";
      };

      "org/gnome/nautilus/preferences".default-folder-viewer = "list-view";
      "org/gnome/nautilus/list-view" = {
        default-zoom-level = "small";
        use-tree-view = true;
      };

      "org/gtk/gtk4/settings/file-chooser" = {
        show-hidden = true;
        sort-directories-first = true;
        view-type = "list";
      };

      "io/github/celluloid-player/celluloid" = {
        always-autohide-cursor = true;
        always-open-new-window = true;
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
        # https://unix.stackexchange.com/a/436347
        switch-input-source = [ "<Alt>Shift_L" ];
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
    };
  }];
}
