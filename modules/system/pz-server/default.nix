{ config, pkgs, lib, ... }:

# A strange amalgam of the following projects:
# 1. https://kevincox.ca/2022/12/09/valheim-server-nixos-v2/
# 2. https://github.com/NixOS/nixpkgs/pull/153023
# Game files are downloaded using steamcmd (1) and the server is run using a
# modified module from an unmerged nixpkgs PR (2). I could not get mods to
# download using the module from the PR, so I made my own solution.

let
  cfg = config.services.pz-server;
  appId = "380870";
in

{
  imports = [ ../steam-install ];

  options.services.pz-server = {
    enable = lib.mkEnableOption "Project Zomboid server (Steam)";

    stateDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/pz-server";
      description = ''
        Server state directory.
      '';
    };

    zomboidDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/pz-server";
      description = ''
        Overwrites the Zomboid homedir containing server data.
      '';
    };

    adminPasswordFile = lib.mkOption {
      type = with lib.types; nullOr path;
      default = null;
      example = lib.literalExpression "/run/secrets/pzserver";
      description = ''
        Path to admin password in a file.
      '';
    };

    openFirewall = lib.mkEnableOption "Opening the firewall ports for Project Zomboid";

    user = lib.mkOption {
      type = lib.types.str;
      default = "pz-server";
      example = lib.literalExpression "pz-server";
      description = ''
        The user under which pz-server runs.
      '';
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "pz-server";
      example = lib.literalExpression "pz-server";
      description = ''
        The group under which pz-server runs.
      '';
    };

    jvmOpts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "-Xms2g"
        "-Xmx2g"
      ];
      description = ''
        Populate the JAVA_TOOL_OPTIONS environment variable.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.steam-install.enable = true;

    users = {
      users.${cfg.user} = {
        isSystemUser = true;
        inherit (cfg) group;
        home = cfg.stateDir;
        createHome = true;
        description = "Project Zomboid server user";
      };

      groups.${cfg.group} = { };
    };

    systemd.services.pz-server = {
      wantedBy = [ "multi-user.target" ];

      # Install the game before launching.
      wants = [ "steam-install@${appId}.service" ];
      after = [
        "steam-install@${appId}.service"
        "network.target"
      ];

      serviceConfig = {
        ExecStart = pkgs.writeShellScript "start-server.sh" ''
          LD_LIBRARY_PATH="${lib.concatStringsSep ":" [
            "${pkgs.zlib}/lib"
            "${lib.getOutput "lib" pkgs.stdenv.cc.cc.lib}/lib"
            "/var/lib/steam/apps/${appId}/jre64/lib/amd64"
            "/var/lib/steam/apps/${appId}/linux64"
            "/var/lib/steam/apps/${appId}/natives"
          ]}"
          export LD_LIBRARY_PATH

          cd /var/lib/steam/apps/${appId}

          # We have to use vendored Java, otherwise downloading mods from Steam
          # Workshop won't work.
          ${lib.getOutput "bin" pkgs.glibc}/bin/ld.so /var/lib/steam/apps/${appId}/jre64/bin/java \
            -Dzomboid.steam=1 \
            -Dzomboid.znetlog=1 \
            -Djava.awt.headless=true \
            -Djava.library.path="${lib.concatStringsSep ":" [
              "/var/lib/steam/apps/${appId}/."
              "/var/lib/steam/apps/${appId}/natives"
              "/var/lib/steam/apps/${appId}/linux64"
            ]}" \
            -Duser.home=${cfg.zomboidDir} \
            -Djava.security.egd=file:/dev/urandom \
            -XX:+UseZGC \
            -XX:-OmitStackTraceInFastThrow \
            -cp "/var/lib/steam/apps/${appId}/java/.:/var/lib/steam/apps/${appId}/java/*" \
            zombie.network.GameServer ${
              lib.optionalString
                (cfg.adminPasswordFile != null)
                "-adminpassword $(${pkgs.systemd}/bin/systemd-creds cat adminpassword)"
            }
        '';
        LoadCredential = "adminpassword:${cfg.adminPasswordFile}";
        Nice = "-5";
        PrivateTmp = true;
        Restart = "always";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.stateDir;
      };

      environment.JAVA_TOOL_OPTIONS = builtins.concatStringsSep " " cfg.jvmOpts;
    };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedUDPPorts = [
        8766
        16261
      ];
    };
  };
}
