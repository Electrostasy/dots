{ config, pkgs, lib, ... }:

let
  arkenfox-src = pkgs.fetchFromGitHub {
    owner = "arkenfox";
    repo = "user.js";
    rev = "111.0";
    sha256 = "sha256-EutseXvFnDkYq95GWiGrTFqI4fqybvsPQlVV0Wy5tFU=";
  };
  arkenfox = builtins.readFile (arkenfox-src + "/user.js");

  # To add new extensions in Firefox:
  # 1. Add the extension to Firefox.
  # 2. To to `about:memory` -> `Measure` -> search for Extensions
  # 3. Locate Extension(id={...}, name="...", baseURL=moz-extension://.../)
  # 4. Yoink the extension ID to use as key.
  # 5. Go to the Firefox extension page and derive the value from the DL link.
  extensions = {
    # Cookies are session-only, this extension blocks or accepts them.
    "idcac-pub@guus.ninja" = "istilldontcareaboutcookies";
    # KeepassXC password manager browser extension.
    "keepassxc-browser@keepassxc.org" = "keepassxc-browser";
    # Redirect websites using RegEx rules.
    "redirector@einaregilsson.com" = "redirector";
    # Try to skip intermediary website redirects.
    "skipredirect@sblask" = "skip-redirect";
    # Mark (skip) sponsored & other video segments on YouTube.
    "sponsorBlocker@ajay.app" = "sponsorblock";
    # Content blocker.
    "uBlock0@raymondhill.net" = "ublock-origin";
  };
in
{
  programs.firefox.enable = true;

  programs.firefox.policies = {
    # List of webextensions to install.
    ExtensionSettings =
      lib.mapAttrs
        (_: name: {
          installation_mode = "normal_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/${name}/latest.xpi";
        })
        extensions;

    # Webextension configuration.
    "3rdparty".Extensions = {
      # https://github.com/gorhill/uBlock/blob/master/platform/common/managed_storage.json
      "uBlock0@raymondhill.net".adminSettings = {
        userSettings = rec {
          uiTheme = "dark";
          importedLists = [
            "https://filters.adtidy.org/extension/ublock/filters/3.txt"
            "https://github.com/DandelionSprout/adfilt/raw/master/LegitimateURLShortener.txt"
          ];
          externalLists = lib.concatStringsSep "\n" importedLists;
        };
        selectedFilterLists = [
          "LTU-0"
          "RUS-0"
          "adguard-annoyance"
          "adguard-social"
          "adguard-spyware-url"
          "easylist"
          "easyprivacy"
          "https://github.com/DandelionSprout/adfilt/raw/master/LegitimateURLShortener.txt"
          "plowe-0"
          "ublock-abuse"
          "ublock-badware"
          "ublock-filters"
          "ublock-privacy"
          "ublock-quick-fixes"
          "ublock-unbreak"
          "urlhaus-1"
        ];
      };
    };
  };

  # Additional extensions by Mozilla for languages.
  programs.firefox.languagePacks = [
    "en-US"
    "lt"
  ];

  # Main configuration is done using autoconfig.js.
  programs.firefox.autoConfig = ''
    /// First line HAS to be a comment.

    // Enable DNS over HTTPS (DoH).
    pref("network.trr.mode", 2);
    pref("network.trr.uri", "https://dns.quad9.net/dns-query");

    /// Load Arkenfox user.js and override settings.
    // Session restore requires keeping history.
    lockPref("browser.startup.page", 3);
    lockPref("privacy.clearOnShutdown.history", false);

    // Don't always ask where to save files.
    lockPref("browser.download.useDownloadDir", true);

    // Session-only permission changes.
    lockPref("permissions.memory_only", true);

    // Disable built-in password manager.
    lockPref("signon.rememberSignons", false);

    // Arkenfox disables DRM already, but the DRM prompt/banner remains.
    lockPref("browser.eme.ui.enabled", false);

    // WebGL is useful for previewing 3D model meshes.
    lockPref("webgl.disabled", false);

    ${builtins.replaceStrings [ "user_pref" ] [ "pref" ] arkenfox}

    /// Personal pref overrides.
    // Insert new tabs after current tab.
    pref("browser.tabs.insertAfterCurrent", true);

    // Disable Pocket.
    pref("extensions.pocket.enabled", false);

    // Force dark mode in the user interface. privacy.resistFingerprinting
    // hides our colorscheme preferences from websites by forcing it to light
    // mode everywhere, so these other prefs don't work with it on.
    // pref("layout.css.prefers-color-scheme.content-override", 0);
    // pref("browser.theme.toolbar-theme", 0);
    // pref("browser.theme.content-theme", 0);
    pref("ui.systemUsesDarkTheme", 1);

    // Enable scrolling using the middle-click.
    pref("general.autoScroll", true);

    // Disable the GTK client side decorations.
    pref("browser.tabs.inTitlebar", ${
      if config.services.xserver.desktopManager.gnome.enable then "1" else "0"
    });

    // Disable PIP.
    pref("media.videocontrols.picture-in-picture.enabled", false);
    pref("media.videocontrols.picture-in-picture.video-toggle.enabled", false);

    // Disable Firefox View.
    pref("browser.tabs.firefox-view", false);

    // Disable Firefox Accounts and Sync.
    pref("identity.fxaccounts.enabled", false);

    // Disable 'Import bookmarks...' button in bookmarks toolbar (on new profile).
    pref("browser.bookmarks.addedImportButton", true);

    // Default browser is managed by NixOS.
    lockPref("pref.general.disable_button.default_browser", true);

    // UI customisation.
    pref("browser.uiCustomization.state", "${lib.escape [ "\"" ] (builtins.toJSON {
      placements = {
        widget-overflow-fixed-list = [];
        nav-bar = [
          "back-button"
          "forward-button"
          "stop-reload-button"
          "sidebar-button"
          "urlbar-container"
          "downloads-button"
          "keepassxc-browser_keepassxc_org-browser-action"
          "ublock0_raymondhill_net-browser-action"
          "add-ons-button"
        ];
        toolbar-menubar = [ "menubar-items" ];
        TabsToolbar = [
          "tabbrowser-tabs"
          "new-tab-button"
        ];
        PersonalToolbar = [ "personal-bookmarks" ];
      };
      seen =
        [ "developer-button" ]
        # Hide all browser extension actions from the toolbars.
        ++ builtins.map (extension:
            lib.toLower
            (builtins.replaceStrings
              [ "." "@" ]
              [ "_" "_" ]
              extension)
            + "-browser-action")
          (builtins.attrNames extensions);

      # No idea what these are for, but this pref is not loaded correctly
      # without them.
      dirtyAreaCache = [];
      currentVersion = 17;
      newElementCount = 0;
    })}");

    // Always show the bookmarks toolbar.
    pref("browser.toolbars.bookmarks.visibility", "always");

    // Hide search shortcuts and suggestions.
    pref("browser.urlbar.shortcuts.bookmarks", false);
    pref("browser.urlbar.shortcuts.history", false);
    pref("browser.urlbar.showSearchSuggestionsFirst", false);
    pref("browser.urlbar.suggest.bookmark", false);
    pref("browser.urlbar.suggest.history", false);
    pref("browser.urlbar.suggest.searches", false);
    pref("browser.urlbar.suggest.topsites", false);
  '';
}
