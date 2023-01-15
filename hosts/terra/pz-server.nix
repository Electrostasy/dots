{ config, lib, ... }:

{
  # The pz-server module uses steamcmd behind the scenes to schedule download
  # and install of game files.
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "steamcmd"
    "steam-run"
    "steam-original"
  ];

  environment.persistence."/state".directories = [
    # Steamcmd files. This and child directories need to be readable by other
    # users, for e.g. pz-server. Note that /state/var/lib/steam has to have
    # these permissions as well.
    { directory = "/var/lib/steam";
      user = "steam";
      group = "steam";
      mode = "u=rwx,g=rx,o=rx";
    }

    # Project Zomboid server files. This directory needs to be executable so
    # that the pz-server user can `cd` into it.
    { directory = "/var/lib/steam/apps/380870";
      user = "steam";
      group = "steam";
      mode = "u=rwx,g=rx,o=rx";
    }

    # Project Zomboid server data.
    { directory = config.services.pz-server.stateDir;
      user = "pz-server";
      group = "pz-server";
      mode = "u=rwx,g=rx,o=";
    }
  ];

  # List all Steam Workshop subscribed mods using command:
  # $ find games/SteamLibrary/steamapps/workshop/content/108600 -type f -name mod.info -exec grep '^id=' {} \; | sed 's/^id=//' | sort

  # List all enabled mods' modids using Fish shell command (use in Mods= in servertest.ini):
  # $ cat ~/games/SteamLibrary/steamapps/compatdata/108600/pfx/drive_c/users/steamuser/Zomboid/mods/default.txt | grep 'mod = ' | sed -e 's/^.*= //' -e 's/,.*$//' | sort | string join ';'

  # List all enabled mods' workshop ids using Fish shell command (use in WorkshopItems= in servertest.ini):
  # $ set -l modids (cat ~/games/SteamLibrary/steamapps/compatdata/108600/pfx/drive_c/users/steamuser/Zomboid/mods/default.txt | grep 'mod = ' | sed -e 's/^.*= //' -e 's/,.*$//')
  # $ for modid in $modids; echo (find ~/games/SteamLibrary/steamapps/workshop/content/108600 -type f -name mod.info -exec grep -l "^id=$modid" {} \; | string split '/')[-4]; end | uniq -u | string join ';'

  # Find generated sandbox settings here:
  # 'games/SteamLibrary/steamapps/compatdata/108600/pfx/drive_c/users/steamuser/Zomboid/Sandbox Presets/Server.cfg'

  # Reset server world:
  # $ sudo rm -rf /var/lib/Zomboid/Saves/Multiplayer/servertest

  sops.secrets.pz-server-admin = {
    sopsFile = ./secrets.yaml;
    mode = "0700";
    owner = config.services.pz-server.user;
    inherit (config.services.pz-server) group;
  };

  services.pz-server = {
    enable = true;

    adminPasswordFile = config.sops.secrets.pz-server-admin.path;
    openFirewall = true;
    jvmOpts = [
      "-Xms8g"
      "-Xmx8g"
    ];
  };
}
