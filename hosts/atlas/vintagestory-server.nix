{ pkgs, lib, ... }:

{
  nixpkgs.config.allowUnfreePackages = [ "vintagestory-server" ];

  fileSystems."/var/lib/vintagestory-server" = {
    device = "/dev/disk/by-path/platform-a40000000.pcie-pci-0000:01:00.0-nvme-1-part1";
    fsType = "btrfs";
    options = [
      "subvol=vintagestory"
      "noatime"
    ];
  };

  systemd = {
    services.vintagestory-server = {
      description = "Vintage Story server";
      wants = [ "network.target" ];
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      confinement = {
        enable = true;

        binSh = null;
      };

      serviceConfig = {
        ExecStart = "${lib.getExe pkgs.vintagestory-server} --dataPath=/var/lib/vintagestory-server";

        # Set up a stdin socket for sending commands to the server.
        Sockets = "vintagestory-server.socket";
        StandardInput = "socket";
        StandardOutput = "journal";
        StandardError = "journal";

        User = "vintagestory";
        Group = "vintagestory";
        StateDirectory = "vintagestory-server";

        BindReadOnlyPaths = [
          "/etc/passwd" # needed to get user info or it crashes.
          "/etc/resolv.conf" # needed to resolve auth server.
          "/etc/ssl/certs/ca-bundle.crt" # needed to connect to auth server.
        ];

        CapabilityBoundingSet = "";
        DeviceAllow = "";
        LockPersonality = true;
        MemoryDenyWriteExecute = false; # needed to load System.Private.CoreLib or it crashes.
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateMounts = true;
        PrivateTmp = true;
        PrivateUsers = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProtectSystem = "strict";
        RemoveIPC = true;
        RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SocketBindAllow = 42420;
        SocketBindDeny = "any";
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
          "@resources" # needed or it coredumps for some reason.
          "~@privileged"
        ];
        UMask = "0177";
      };
    };

    sockets.vintagestory-server = {
      unitConfig = {
        PartOf = "vintagestory-server.service";
      };

      socketConfig = {
        # Send commands to the FIFO:
        # $ echo '/help' > /run/vintagestory-server.stdin
        # Read the output:
        # $ journalctl -eu vintagestory-server -f
        ListenFIFO = "%t/vintagestory-server.stdin";
      };
    };
  };

  networking.firewall = {
    allowedTCPPorts = [ 42420 ];
    allowedUDPPorts = [ 42420 ];
  };

  users = {
    users.vintagestory = {
      isSystemUser = true;
      group = "vintagestory";
    };

    groups.vintagestory = { };
  };
}
