{ config, pkgs, ... }:

{
  hardware.opengl = {
    enable = true;
    driSupport = true;
  };

  security = {
    pam.services.gamescope.text = ''
      auth    required pam_unix.so nullok
      account required pam_unix.so
      session required pam_unix.so
      session required ${pkgs.systemd}/lib/security/pam_systemd.so
    '';

    wrappers.gamescope = {
      owner = "gamescope";
      group = "gamescope";
      # Allow gamescope to re-nice itself and use realtime priority compute
      capabilities = "cap_sys_nice+pe";
      source = "${pkgs.gamescope}/bin/gamescope";
    };
  };

  users = {
    groups.gamescope = {};
    users.gamescope = {
      isSystemUser = true;
      group = "gamescope";
      extraGroups = [ "video" "render" ];
    };
  };

  systemd = {
    defaultUnit = "graphical.target";
    targets.graphical.wants = [ "gamescope.service" ];
    services."gamescope@" = {
      enable = true;
      after = [
        # Make surer we are started after logins are permitted
        "systemd-user-sessions.service"
        # D-Bus is necessary for contacting logind, which is required
        "dbus.socket"
        "systemd-logind.service"
        # We require a tty, /dev/console links to /dev/pts/0
        "console-getty.service"
      ];
      before = [
        # Since we are part of the graphical session, make sure we are started
        # before it is complete
        "graphical.target"
      ];
      wants = [
        "dbus.socket"
        "systemd-logind.service"
      ];
      wantedBy = [ "graphical.target" ];
      conflicts = [ "console-getty.service" ];

      restartIfChanged = false;
      unitConfig = {
        ConditionPathExists = "/dev/console";
        DevicePolicy = "closed";
        DeviceAllow = [
          "/dev/dri/card0 rw"
          "/dev/dri/renderD128 rw"
        ];
      };
      serviceConfig = {
        Type = "simple";
        ExecStart = "${config.security.wrapperDir}/gamescope -W 3840 -H 2160 -r 120 -e";
        User = "gamescope";
        # Log this user with utmp, letting it show up with commands 'w' and 'who'.
        # This is needed since we replace (a)getty.
        UtmpIdentifier = "%n";
        UtmpMode = "user";
        # A virtual terminal is needed
        TTYPath = "/dev/console";
        TTYReset = "yes";
        TTYVHangup = "yes";
        TTYVTDisallocate = "yes";
        # Fail to start if not controlling the virtual terminal
        StandardInput = "tty-fail";
        StandardError = "journal";
        StandardOutput = "journal";
        # Set up a full custom user session for this user
        PAMName = "gamescope";
      };
    };
  };
}
