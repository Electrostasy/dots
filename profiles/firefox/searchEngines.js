AddonManager.readyPromise.then(() => {
  const newEngines = [
    {
      name: "DuckDuckGo",
      keyword: "@d",
      favicon_url: "https://duckduckgo.com/favicon.ico",
      search_url: "https://duckduckgo.com/?va=u&q={searchTerms}",
      is_default: true,
    },
    {
      name: "YouTube",
      keyword: "@yt",
      favicon_url: "https://www.youtube.com/favicon.ico",
      search_url: "https://www.youtube.com/results?search_query={searchTerms}"
    },
    {
      name: "AniList",
      keyword: "@al",
      favicon_url: "https://anilist.co/favicon.ico",
      search_url: "https://anilist.co/search/anime?search={searchTerms}"
    },
    {
      name: "GitHub",
      keyword: "@gh",
      favicon_url: "https://github.com/favicon.ico",
      search_url: "https://github.com/search?q={searchTerms}&type=repositories"
    },
    {
      name: "1337x",
      keyword: "@to",
      favicon_url: "https://1337x.to/favicon.ico",
      search_url: "https://1337x.to/search/{searchTerms}/1/"
    },
    {
      name: "Printables",
      keyword: "@3d",
      favicon_url: "https://www.printables.com/favicon.ico",
      search_url: "https://www.printables.com/search/all?q={searchTerms}"
    },
    {
      name: "NixOS Packages",
      keyword: "@np",
      favicon_url: "https://nixos.org/favicon.ico",
      search_url: "https://search.nixos.org/packages?channel=unstable&query={searchTerms}"
    },
    {
      name: "NixOS Modules",
      keyword: "@nm",
      favicon_url: "https://nixos.org/favicon.ico",
      search_url: "https://search.nixos.org/options?channel=unstable&query={searchTerms}"
    },
    {
      name: "NixOS Wiki",
      keyword: "@nw",
      favicon_url: "https://nixos.org/favicon.ico",
      search_url: "https://nixos.wiki/index.php?search={searchTerms}"
    },
    {
      name: "NixOS Discourse",
      keyword: "@nd",
      favicon_url: "https://nixos.org/favicon.ico",
      search_url: "https://discourse.nixos.org/search?q={searchTerms}"
    },
  ];

  const setDefaultEngine = function (engine) {
    Services.search.setDefault(engine, Services.search.CHANGE_REASON_USER);
    Services.search.setDefaultPrivate(engine, Services.search.CHANGE_REASON_USER);
  };

  Services.search.getEngines().then(engines => {
    // We have to have at least 1 search engine, so create a temporary to remove later.
    Services.search.addUserEngine("_temporary", "https://127.0.0.1/fake?q={searchTerms}", "");
    let temp_engine = Services.search.getEngineByName("_temporary");
    setDefaultEngine(temp_engine);

    // Nuke all the current search engines.
    for (let engine of engines) {
      if (engine.isAppProvided) {
        let id = engine._extensionID;
        Services.search.removeWebExtensionEngine(id);
        AddonManager.getAddonByID(id).then(addon => { addon.uninstall(); });
      } else {
        Services.search.removeEngine(engine);
      }
    }

    // Add our own search engines.
    // TODO: This still fails because of pre-existing engines, and so we can't remove
    // the temporary.
    for (let engine of newEngines) {
      let maybeExists = Services.search.getEngineByName(engine.name);
      if (!maybeExists) {
        Services.search.addUserEngine(engine.name, engine.search_url, engine.keyword);
      }

      if (engine.is_default) {
        setDefaultEngine(Services.search.getEngineByName(engine.name));
      }
    }

    Services.search.removeEngine(temp_engine);
  })
})
