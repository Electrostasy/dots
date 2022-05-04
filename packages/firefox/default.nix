{ pkgs, lib, fetchFirefoxAddon, ... }:

pkgs.wrapFirefox pkgs.firefox-esr-unwrapped {
  forceWayland = true;
  # New extensions: use lib.fakeSha256, rebuild, then put in correct sha256
  nixExtensions = [
    (fetchFirefoxAddon {
      name = "canvas-blocker";
      url = "https://addons.mozilla.org/android/downloads/file/3910598/canvasblocker-1.8-an+fx.xpi";
      sha256 = "sha256-gXphgb6HdmjsodD++ez3iciY5tfZPcp+KUedQPmGyEQ=";
    })
    (fetchFirefoxAddon {
      name = "https-everywhere";
      url = "https://addons.mozilla.org/firefox/downloads/file/3809748/https_everywhere-2021.7.13-an+fx.xpi";
      sha256 = "sha256-4mFGG11NNiEoX85wdzVYGE1pHGFLMwdE2rZy8DLbcxw=";
    })
    (fetchFirefoxAddon {
      name = "privacy-badger";
      url = "https://addons.mozilla.org/firefox/downloads/file/3872283/privacy_badger-2021.11.23.1-an+fx.xpi";
      sha256 = "sha256-UCdM0oBBO9DnxLU9LvPQGfajzhSnOW/tbSSPKVrn9j4=";
    })
    (fetchFirefoxAddon {
      name = "ublock-origin";
      url = "https://addons.mozilla.org/android/downloads/file/3913320/ublock_origin-1.41.8-an+fx.xpi";
      sha256 = "sha256-Unx1JxFqbG/925Y837kBUY1W9iTPySL26rMpFrJOj10=";
    })
    (fetchFirefoxAddon {
      name = "localcdn";
      url = "https://addons.mozilla.org/firefox/downloads/file/3902456/localcdn-2.6.23-an+fx.xpi";
      sha256 = "sha256-/yoKZKDNyKpisW8fPMQSAXYAM3MSdrQn7wIpDLU+ZIA=";
    })
    (fetchFirefoxAddon {
      name = "multi-account-containers";
      url = "https://addons.mozilla.org/firefox/downloads/file/3907697/firefox_multi_account_containers-8.0.6-fx.xpi";
      sha256 = "sha256-2T2wsUbvaYIBEgDli4r6nEO9w0URYzNZOCZmfF21z6s=";
    })
    (fetchFirefoxAddon {
      name = "sponsorblock";
      url = "https://addons.mozilla.org/firefox/downloads/file/3923928/sponsorblock_skip_sponsorships_on_youtube-4.2.1-an+fx.xpi";
      sha256 = "sha256-SPBEORMKAB5zPnJr9U8H2DWErO+X/Ni2yofzPLlHvgE=";
    })
    (fetchFirefoxAddon {
      name = "consent-o-matic";
      url = "https://addons.mozilla.org/firefox/downloads/file/3931888/consent_o_matic-1.0.0-an+fx.xpi";
      sha256 = "sha256-ErM6Qvkv1Tub1W8peKvtqGaBNh8jVGleXCn24zTPQw0=";
    })
  ];
  # Policy list https://github.com/mozilla/policy-templates/blob/master/README.md
  extraPolicies = {
    CaptivePortal = false;
    DNSOverHTTPS = { Enabled = false; };
    DisableAppUpdate = true;
    DisableBuiltinPDFViewer = true;
    DisableFirefoxAccounts = true;
    DisableFirefoxScreenshots = true;
    DisableFirefoxStudies = true;
    DisablePocket = true;
    DisableSystemAddonUpdate = true;
    DisableTelemetry = true;
    NetworkPrediction = false;
    PasswordManagerEnabled = false;
    SearchEngines = {
      Default = "DuckDuckGo";
      PreventInstalls = true;
      Remove = [ "Amazon.com" "Bing" "Wikipedia (en)" ];
    };
    FirefoxHome = {
      Pocket = false;
      Snippets = false;
    };
    UserMessaging = {
      WhatsNew = false;
      ExtensionRecommendations = false;
      FeatureRecommendations = false;
      UrlbarInterventions = false;
      SkipOnboarding = true;
    };
  };
  extraPrefs = ''
    // Since we fetch extensions ourselves, we must have firefox
    // allow unsigned extensions
    lockPref("xpinstall.signatures.required", false);
    lockPref("security.identityblock.show_extended_validation", true);
    lockPref("devtools.theme", "dark");
    pref("media.videocontrols.picture-in-picture.enabled", false);
    pref("media.videocontrols.picture-in-picture.video-toggle.enabled", false);
    pref("general.autoScroll", true);
    pref("extensions.activeThemeID", "firefox-compact-dark@mozilla.org");

    // Privacy changes
    /*
    pref("app.normandy.api_url", "");
    pref("app.normandy.enabled", false);
    pref("app.shield.optoutstudies.enabled", false);
    pref("app.update.auto", false);
    pref("beacon.enabled", false);
    pref("breakpad.reportURL", "");
    pref("browser.aboutConfig.showWarning", false);
    pref("browser.cache.offline.enable", false);
    pref("browser.crashReports.unsubmittedCheck.autoSubmit", false);
    pref("browser.crashReports.unsubmittedCheck.autoSubmit2", false);
    pref("browser.crashReports.unsubmittedCheck.enabled", false);
    pref("browser.disableResetPrompt", true);
    pref("browser.fixup.alternate.enabled", false);
    pref("browser.newtab.preload", false);
    pref("browser.newtabpage.activity-stream.section.highlights.includePocket", false);
    pref("browser.newtabpage.enabled", false);
    pref("browser.newtabpage.enhanced", false);
    pref("browser.newtabpage.introShown", true);
    pref("browser.safebrowsing.appRepURL", "");
    pref("browser.safebrowsing.blockedURIs.enabled", false);
    pref("browser.safebrowsing.downloads.enabled", false);
    pref("browser.safebrowsing.downloads.remote.enabled", false);
    pref("browser.safebrowsing.downloads.remote.url", "");
    pref("browser.safebrowsing.enabled", false);
    pref("browser.safebrowsing.malware.enabled", false);
    pref("browser.safebrowsing.phishing.enabled", false);
    pref("browser.search.suggest.enabled", false);
    pref("browser.selfsupport.url", "");
    pref("browser.send_pings", false);
    pref("browser.sessionstore.privacy_level", 2);
    pref("browser.shell.checkDefaultBrowser", false);
    pref("browser.startup.homepage_override.mstone", "ignore");
    pref("browser.tabs.crashReporting.sendReport", false);
    pref("browser.urlbar.groupLabels.enabled", false);
    pref("browser.urlbar.quicksuggest.enabled", false);
    pref("browser.urlbar.speculativeConnect.enabled", false);
    pref("browser.urlbar.trimURLs", false);
    pref("datareporting.healthreport.service.enabled", false);
    pref("datareporting.healthreport.uploadEnabled", false);
    pref("datareporting.policy.dataSubmissionEnabled", false);
    pref("device.sensors.ambientLight.enabled", false);
    pref("device.sensors.enabled", false);
    pref("device.sensors.motion.enabled", false);
    pref("device.sensors.orientation.enabled", false);
    pref("device.sensors.proximity.enabled", false);
    pref("dom.battery.enabled", false);
    pref("dom.event.clipboardevents.enabled", true); // If these are disabled, no more copying in webapps
    pref("dom.storage.enabled", false);
    // pref("dom.webaudio.enabled", false); // If false, discord audio is broken
    pref("experiments.activeExperiment", false);
    pref("experiments.enabled", false);
    pref("experiments.manifest.uri", "");
    pref("experiments.supported", false);
    pref("extensions.getAddons.cache.enabled", false);
    pref("extensions.getAddons.showPane", false);
    pref("extensions.greasemonkey.stats.optedin", false);
    pref("extensions.greasemonkey.stats.url", "");
    pref("extensions.pocket.enabled", false);
    pref("extensions.screenshots.upload-disabled", true);
    pref("extensions.shield-recipe-client.api_url", "");
    pref("extensions.shield-recipe-client.enabled", false);
    pref("extensions.webservice.discoverURL", "");
    pref("general.useragent.override", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/95.0.4638.69 Safari/537.36");
    pref("media.autoplay.default", 1);
    pref("media.autoplay.enabled", false);
    pref("media.eme.enabled", false);
    pref("media.gmp-widevinecdm.enabled", false);
    // pref("media.navigator.enabled", false);
    pref("media.video_stats.enabled", false);
    pref("network.IDN_show_punycode", true);
    pref("network.allow-experiments", false);
    pref("network.captive-portal-service.enabled", false);
    pref("network.cookie.cookieBehavior", 1);
    pref("network.dns.disablePrefetch", true);
    pref("network.dns.disablePrefetchFromHTTPS", true);
    pref("network.http.referer.spoofSource", true);
    pref("nework.http.speculative-parallel-limit", 0);
    pref("network.predictor.enable-prefetch", false);
    pref("network.predictor.enabled", false);
    pref("network.prefetch-next", false);
    pref("network.trr.mode", 5);
    pref("pdfjs.enableScripting", false);
    pref("privacy.donottrackheader.enabled", true);
    pref("privacy.donottrackheader.value", 1);
    pref("privacy.firstparty.isolate", true);
    pref("privacy.resistFingerprinting", true);
    pref("privacy.trackingprotection.cryptomining.enabled", true);
    pref("privacy.trackingprotection.enabled", true);
    pref("privacy.trackingprotection.fingerprinting.enabled", true);
    pref("privacy.trackingprotection.pbmode.enabled", true);
    pref("privacy.usercontext.about_newtab_segregation.enabled", true);
    pref("security.ssl.disable_session_identifiers", true);
    pref("services.sync.prefs.sync.browser.newtabpage.activity-stream.showSponsoredTopSite", false);
    pref("signon.autofillForms", false);
    pref("toolkit.telemetry.archive.enabled", false);
    pref("toolkit.telemetry.bhrPing.enabled", false);
    pref("toolkit.telemetry.cachedClientID", "");
    pref("toolkit.telemetry.enabled", false);
    pref("toolkit.telemetry.firstShutdownPing.enabled", false);
    pref("toolkit.telemetry.hybridContent.enabled", false);
    pref("toolkit.telemetry.newProfilePing.enabled", false);
    pref("toolkit.telemetry.prompted", 2);
    pref("toolkit.telemetry.rejected", true);
    pref("toolkit.telemetry.reportingpolicy.firstRun", false);
    pref("toolkit.telemetry.server", "");
    pref("toolkit.telemetry.shutdownPingSender.enabled", false);
    pref("toolkit.telemetry.unified", false);
    pref("toolkit.telemetry.unifiedIsOptIn", false);
    pref("toolkit.telemetry.updatePing.enabled", false);
    pref("webgl.disabled", true);
    pref("webgl.renderer-string-override", " ");
    pref("webgl.vendor-string-override", " ");
    */
  '';
}
