{
  fileSystems."/var/lib/fail2ban" = {
    device = "/dev/disk/by-label/pidata";
    fsType = "btrfs";
    options = [
      "subvol=fail2ban"
      "noatime"
    ];
  };

  services.fail2ban = {
    enable = true;

    ignoreIP = [
      "100.64.0.0/24"
      "192.168.0.0/24"
    ];

    bantime-increment = {
      enable = true;

      rndtime = "15m";
      maxtime = "1m";
      overalljails = true;
    };

    jails = {
      nginx-bots.settings = {
        filter = "nginx-bots";
        logpath = "/var/log/nginx/access.log";
        backend = "auto";
        findtime = "1w";
        bantime = "1h";
      };
    };
  };

  # This could be less broad, but with the amount of bots, it might be better
  # to work with a whitelist of known good patterns and blanket ban everything
  # else.
  environment.etc."fail2ban/filter.d/nginx-bots.local".text = ''
    [Definition]
    failregex = ^<ADDR> -.*"(GET|HEAD|POST|PUT).*" (400|401|403|404) .*$
    ignoreregex = ^.*"GET /.well-known/acme-challenge/[a-zA-Z0-9\-_]{43} .*$
                  ^.*"(GET|HEAD|PUT) /xmpp/file_share/.+$
  '';
}
