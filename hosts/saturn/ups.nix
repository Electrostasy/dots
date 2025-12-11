{ config, lib, ... }:

{
  sops.secrets.upsuserPassword = {
    mode = "0400";
    group = config.users.groups.upsuser.name;
  };

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

        NOTIFYFLAG = [
          [ "ONLINE" "SYSLOG+WALL" ]
          [ "ONBATT" "SYSLOG+WALL" ]
          [ "LOWBATT" "SYSLOG+WALL" ]
          [ "REPLBATT" "SYSLOG+WALL" ]
          [ "FSD" "SYSLOG+WALL" ]
          [ "SHUTDOWN" "SYSLOG+WALL" ]
          [ "COMMOK" "SYSLOG+WALL" ]
          [ "COMMBAD" "SYSLOG+WALL" ]
          [ "NOCOMM" "SYSLOG+WALL" ]
          [ "NOPARENT" "SYSLOG+WALL" ]
          [ "SUSPEND_STARTING" "SYSLOG+WALL" ]
          [ "SUSPEND_FINISHED" "SYSLOG+WALL" ]
        ];

        RBWARNTIME = 216000;
        NOCOMMWARNTIME = 300;
        FINALDELAY = 0;
        SHUTDOWNCMD = ''"systemctl hibernate"'';
      };
    };
  };

  programs.dconf.profiles.user.databases = [{
    settings = {
      # Connected UPS confuses the settings daemon into thinking we are on a
      # portable device with a battery, so disable sleep on inactivity.
      "org/gnome/settings-daemon/plugins/power".sleep-inactive-battery-type = "nothing";
    };
  }];
}
