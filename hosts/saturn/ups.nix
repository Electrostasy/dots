{ config, pkgs, lib, ... }:

{
  sops.secrets.upsuserPassword = {
    mode = "0400";
    group = config.users.groups.upsuser.name;
  };

  security.sudo.extraRules = [
    # Allow execution of "notify-send" by user `upsmon` and group `upsmon`
    # without requiring a password.
    {
      users = [ "${config.power.ups.upsmon.user}" ];
      groups = [ "${config.power.ups.upsmon.group}" ];
      commands = [
        { command = lib.getExe pkgs.libnotify; options = [ "NOPASSWD" "SETENV" ]; }
      ];
    }
  ];

  users.groups.upsuser = { };

  power.ups = {
    enable = true;

    ups."APC" = {
      driver = "usbhid-ups";
      description = "APC Back-UPS RS 1300MI";
      port = "auto";

      directives = [
        "vendorid = 051D"
        "productid = 0002"
        "offdelay = 60"
        "ondelay = 70"
        "lowbatt = 40"
        "ignorelb"
      ];
    };

    upsd.listen = [
      { address = "127.0.0.1"; }
    ];

    users.upsuser = {
      passwordFile = config.sops.secrets.upsuserPassword.path;
      upsmon = "primary";
    };

    upsmon = {
      monitor."APC".user = "upsuser";

      settings = {
        NOTIFYMSG = [
          [ "ONLINE" ''"UPS %s: On line power."'' ]
          [ "ONBATT" ''"UPS %s: On battery."'' ]
          [ "LOWBATT" ''"UPS %s: Battery is low."'' ]
          [ "REPLBATT" ''"UPS %s: Battery needs to be replaced."'' ]
          [ "FSD" ''"UPS %s: Forced shutdown in progress."'' ]
          [ "SHUTDOWN" ''"Auto logout and shutdown proceeding."'' ]
          [ "COMMOK" ''"UPS %s: Communications (re-)established."'' ]
          [ "COMMBAD" ''"UPS %s: Communications lost."'' ]
          [ "NOCOMM" ''"UPS %s: Not available."'' ]
          [ "NOPARENT" ''"upsmon parent dead, shutdown impossible."'' ]
          [ "SUSPEND_STARTING" ''UPS %S: System is entering suspension.'' ]
          [ "SUSPEND_FINISHED" ''UPS %S: System has left suspension.'' ]
        ];

        NOTIFYCMD = "${pkgs.writeShellScript "upsmon-notify.sh" ''
          ${lib.getExe pkgs.notify-send-all} \
            -a 'Network UPS Tools' \
            -i 'uninterruptible-power-supply' \
            -c 'device' \
            "Received event $NOTIFYTYPE from UPS $UPSNAME" \
            "$*"
        ''}";

        NOTIFYFLAG = [
          [ "ONLINE" "SYSLOG+WALL+EXEC" ]
          [ "ONBATT" "SYSLOG+WALL+EXEC" ]
          [ "LOWBATT" "SYSLOG+WALL+EXEC" ]
          [ "REPLBATT" "SYSLOG+WALL+EXEC" ]
          [ "FSD" "SYSLOG+WALL+EXEC" ]
          [ "SHUTDOWN" "SYSLOG+WALL+EXEC" ]
          [ "COMMOK" "SYSLOG+WALL+EXEC" ]
          [ "COMMBAD" "SYSLOG+WALL+EXEC" ]
          [ "NOCOMM" "SYSLOG+WALL+EXEC" ]
          [ "NOPARENT" "SYSLOG+WALL" ]
          [ "SUSPEND_STARTING" "SYSLOG+WALL+EXEC" ]
          [ "SUSPEND_FINISHED" "SYSLOG+WALL+EXEC" ]
        ];

        RBWARNTIME = 216000;
        NOCOMMWARNTIME = 300;
        FINALDELAY = 0;
        SHUTDOWNCMD = ''"systemctl hibernate"'';
      };
    };
  };

  # The FSD flag cannot be removed unless the daemon restarts after waking.
  systemd.services.upsd.after = [
    "suspend.target"
    "hibernate.target"
  ];
}
