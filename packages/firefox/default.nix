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
        selectedFilterLists = [
          "adguard-annoyance"
          "adguard-social"
          "adguard-spyware"
          "adguard-spyware-url"
          "easylist"
          "easyprivacy"
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

    SearchEngines = {
      Default = "DuckDuckGo";
      PreventInstalls = true;
      Remove = [ "Amazon.com" "Bing" "Wikipedia (en)" ];
    };
  };

  extraPrefsFiles =
    let
      arkenfox = fetchFromGitHub {
        owner = "arkenfox";
        repo = "user.js";
        rev = "105.0";
        sha256 = "sha256-XUjX+Tno3EU/3IXR/WCn4M5gVR+sKjCzpKcV31dqzWA=";
      };
    in
      lib.singleton "${arkenfox}/user.js";

  extraPrefs = ''
    user_pref("general.autoScroll", true);
    user_pref("extensions.activeThemeID", "firefox-compact-dark@mozilla.org");

    // Arkenfox user.js overrides
    user_pref("app.update.auto", false);
    user_pref("browser.eme.ui.enabled", false);
    user_pref("browser.search.update", false);
    user_pref("browser.urlbar.autoFill", false);
    user_pref("browser.urlbar.maxRichResults", 0);
    user_pref("browser.urlbar.suggest.bookmark", false);
    user_pref("browser.urlbar.suggest.history", false);
    user_pref("browser.urlbar.suggest.openpage", false);
    user_pref("browser.urlbar.suggest.topsites", false)
    user_pref("dom.security.https_only_mode_pbm", true);
    user_pref("dom.security.https_only_mode.upgrade_local", true);
    user_pref("extensions.formautofill.addresses.enabled", false);
    user_pref("extensions.formautofill.creditCards.enabled", false);
    user_pref("extensions.formautofill.heuristics.enabled", false);
    user_pref("extensions.pocket.enabled", false);
    user_pref("extensions.screenshots.disabled", true);
    user_pref("extensions.webextensions.restrictedDomains", "");
    user_pref("identity.fxaccounts.enabled", false);
    user_pref("layout.spellcheckDefault", 2);
    user_pref("media.autoplay.blocking_policy", 2);
    user_pref("media.autoplay.default", 5);
    user_pref("permissions.default.shortcuts", 2);
    user_pref("permissions.memory_only", true);
    user_pref("reader.parse-on-load.enabled", false);
    user_pref("signon.rememberSignons", false);
    user_pref("startup.homepage_override_url", "");
    user_pref("startup.homepage_welcome_url", "");
    user_pref("startup.homepage_welcome_url.additional", "");
    user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
    user_pref("ui.systemUsesDarkTheme", 1);
  '';
}
