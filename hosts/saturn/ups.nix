{ config, pkgs, lib, ... }:

{
  sops.secrets.upsuserPassword = {
    mode = "0400";
    group = config.users.groups.upsuser.name;
  };

  security.sudo.extraRules = [
    {
      users = [ "${config.power.ups.upsmon.user}" ];
      groups = [ "${config.power.ups.upsmon.group}" ];
      commands = [
        { command = "${lib.getExe pkgs.notify-send-all}"; options = [ "NOPASSWD" ]; }
      ];
    }
  ];

  users.groups.upsuser = { };

  power.ups = {
    enable = true;

    ups."APC" = {
      driver = "usbhid-ups";
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
          [ "ONLINE" ''"%s: On line power."'' ]
          [ "ONBATT" ''"%s: On battery."'' ]
          [ "LOWBATT" ''"%s: Battery is low."'' ]
          [ "REPLBATT" ''"%s: Battery needs to be replaced."'' ]
          [ "FSD" ''"%s: Forced shutdown in progress."'' ]
          [ "SHUTDOWN" ''"Auto logout and shutdown proceeding."'' ]
          [ "COMMOK" ''"%s: Communications (re-)established."'' ]
          [ "COMMBAD" ''"%s: Communications lost."'' ]
          [ "NOCOMM" ''"%s: Not available."'' ]
          [ "NOPARENT" ''"upsmon parent dead, shutdown impossible."'' ]
          [ "SUSPEND_STARTING" ''"%s: System is entering suspension."'' ]
          [ "SUSPEND_FINISHED" ''"%s: System has left suspension."'' ]
        ];

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

        NOTIFYCMD = "${lib.getExe pkgs.upsmon-notify}";

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
