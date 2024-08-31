{ pkgs, lib, ... }:

let
  # To add new extensions in Firefox:
  # 1. Add the extension to Firefox.
  # 2. Go to `about:memory` -> `Measure` -> search for Extensions
  # 3. Locate Extension(id={...}, name="...", baseURL=moz-extension://.../)
  # 4. Extension ID is the attribute name.
  # 5. Go to the Firefox extension's page and the download link contains the attribute value.
  extensions = {
    "keepassxc-browser@keepassxc.org" = "keepassxc-browser";
    "skipredirect@sblask" = "skip-redirect";
    "sponsorBlocker@ajay.app" = "sponsorblock";
    "uBlock0@raymondhill.net" = "ublock-origin";
  };
in

{
  environment.persistence.state.users.electro.directories = [
    ".mozilla/firefox"
    ".mozilla/native-messaging-hosts"
  ];

  programs.firefox = {
    enable = true;

    package = pkgs.firefox.override {
      extraPrefsFiles = [
        "${pkgs.arkenfox-userjs}/user.cfg"

        (pkgs.writeText "arkenfox-userjs-overrides.cfg" /* javascript */ ''
          /// arkenfox user.js overrides.
          lockPref("privacy.clearOnShutdown.history", false); // Session restore requires keeping history.
          lockPref("browser.startup.page", 3);
          lockPref("browser.download.useDownloadDir", true); // Don't always ask where to save files.
          lockPref("permissions.memory_only", true); // Session-only permission changes.
          lockPref("signon.rememberSignons", false); // Disable built-in password manager.
          lockPref("browser.eme.ui.enabled", false); // Disable DRM prompt/banner.
        '')
      ];
    };

    policies = {
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
            "adguard-cookies"
            "adguard-mobile-app-banners"
            "adguard-other-annoyances"
            "adguard-popup-overlays"
            "adguard-social"
            "adguard-spyware-url"
            "adguard-widgets"
            "easylist"
            "easylist-annoyances"
            "easylist-chat"
            "easylist-newsletters"
            "easylist-notifications"
            "easyprivacy"
            "fanboy-cookiemonster"
            "https://filters.adtidy.org/extension/ublock/filters/3.txt"
            "https://github.com/DandelionSprout/adfilt/raw/master/LegitimateURLShortener.txt"
            "plowe-0"
            "ublock-annoyances"
            "ublock-badware"
            "ublock-cookies-adguard"
            "ublock-cookies-easylist"
            "ublock-filters"
            "ublock-privacy"
            "ublock-quick-fixes"
            "ublock-unbreak"
            "urlhaus-1"
          ];
        };
      };
    };

    autoConfig = /* javascript */ ''
      /// First line HAS to be a comment.
      pref("network.trr.mode", 2); // Enable DNS over HTTPS (DoH).
      pref("network.trr.uri", "https://dns.quad9.net/dns-query");
      pref("browser.tabs.insertAfterCurrent", true); // Insert new tabs after current tab.
      pref("extensions.pocket.enabled", false); // Disable Pocket.
      pref("general.autoScroll", true); // Enable scrolling using the middle-click.
      pref("media.videocontrols.picture-in-picture.enabled", false); // Disable PIP.
      pref("browser.tabs.firefox-view", false); // Disable Firefox View.
      pref("identity.fxaccounts.enabled", false); // Disable Firefox Accounts and Sync.
      pref("browser.bookmarks.addedImportButton", true); // Disable 'Import bookmarks...' toolbar button.
      pref("browser.toolbars.bookmarks.visibility", "always"); // Always show the bookmarks toolbar.
      pref("pref.general.disable_button.default_browser", true); // Default browser is managed by NixOS.

      // Hide suggestions in urlbar, we can use * for bookmarks, % for tabs and ^
      // for history instead.
      pref("browser.urlbar.shortcuts.bookmarks", false);
      pref("browser.urlbar.shortcuts.history", false);
      pref("browser.urlbar.showSearchSuggestionsFirst", false);
      pref("browser.urlbar.suggest.bookmark", false);
      pref("browser.urlbar.suggest.history", false);
      pref("browser.urlbar.suggest.searches", false);
      pref("browser.urlbar.suggest.recentsearches", false);
      pref("browser.urlbar.suggest.topsites", false);

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
            "unified-extensions-button"
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
        currentVersion = 19;
        newElementCount = 0;
      })}");
    '';
  };
}
