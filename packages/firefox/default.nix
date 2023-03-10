{ pkgs, lib, ... }:

with pkgs;

wrapFirefox firefox-unwrapped {
  extraPolicies = {
    # Instead of installing extensions with Nix, we declare what extensions we
    # want and have them downloaded automatically. Nix extensions appear to use
    # these policy settings under-the-hood too, but with pre-downloaded files.
    ExtensionSettings =
      let
        installFn = lib.mapAttrs (_: name: {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/${name}/latest.xpi";
        });

        # Add new extension in Firefox, go to `about:memory` -> `Measure` -> search for Extensions
        # and locate the Extension(id={...}, name="...", baseURL=moz-extension://.../) fields
        extensions = {
          # Must-have
          "uBlock0@raymondhill.net" = "ublock-origin";
          "smart-referer@meh.paranoid.pk" = "smart-referer";
          "skipredirect@sblask" = "skip-redirect";
          "CanvasBlocker@kkapsner.de" = "canvasblocker";

          # QoL
          "redirector@einaregilsson.com" = "redirector";
          "sponsorBlocker@ajay.app" = "sponsorblock";
          "keepassxc-browser@keepassxc.org" = "keepassxc-browser";
          "gdpr@cavi.au.dk" = "consent-o-matic";
        };
      in
      installFn extensions;

    # Some extensions support configuration via policy settings, in which case
    # we can declare what configuration we want for them.
    "3rdparty".Extensions = {
      "uBlock0@raymondhill.net".adminSettings = {
        userSettings = {
          externalLists = lib.concatStringsSep "\n" [
            "https://filters.adtidy.org/extension/ublock/filters/3.txt"
            "https://github.com/DandelionSprout/adfilt/raw/master/LegitimateURLShortener.txt"
          ];
          importedLists = [
            "https://filters.adtidy.org/extension/ublock/filters/3.txt"
            "https://github.com/DandelionSprout/adfilt/raw/master/LegitimateURLShortener.txt"
          ];
        };
        selectedFilterLists = [
          "adguard-annoyance"
          "adguard-social"
          "adguard-spyware"
          "adguard-spyware-url"
          "easylist"
          "easyprivacy"
          "https://github.com/DandelionSprout/adfilt/raw/master/LegitimateURLShortener.txt"
          "LTU-0"
          "plowe-0"
          "RUS-0"
          "ublock-abuse"
          "ublock-badware"
          "ublock-filters"
          "ublock-privacy"
          "ublock-quick-fixes"
          "ublock-unbreak"
          "urlhaus-1"
          "user-filters"
        ];
      };
    };
  };

  extraPrefsFiles =
    let
      arkenfox = fetchFromGitHub {
        owner = "arkenfox";
        repo = "user.js";
        rev = "109.0";
        sha256 = "sha256-ebSx6DaXoGKcCoK6UcDnWvdAW6J2X6pJRPD1Pw7UNOw=";
      };
    in
      lib.singleton "${arkenfox}/user.js";

  extraPrefs = ''
    user_pref("general.autoScroll", true);
    user_pref("extensions.activeThemeID", "firefox-compact-dark@mozilla.org");
    user_pref("browser.tabs.insertAfterCurrent", true);

    // Arkenfox user.js overrides.
    user_pref("browser.download.useDownloadDir", true);
    user_pref("browser.startup.page", 3);
    user_pref("browser.urlbar.suggest.bookmark", false);
    user_pref("browser.urlbar.suggest.history", false);
    user_pref("browser.urlbar.suggest.openpage", false);
    user_pref("browser.urlbar.suggest.topsites", false);
    user_pref("dom.popup_allowed_events", "click dblclick mousedown pointerdown");
    user_pref("extensions.webextensions.restrictedDomains", "");
    user_pref("permissions.default.shortcuts", 2);
    user_pref("permissions.memory_only", true);
    user_pref("signon.rememberSignons", false);
  '';
}
