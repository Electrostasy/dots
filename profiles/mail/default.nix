{ config, pkgs, ... }:

let
  address = "0x6776.lt";
  mailAddress = "mx.${address}";
in
{
  sops.secrets.dkim = {
    sopsFile = ./secrets.yaml;
    mode = "0700";
    owner = config.services.rspamd.user;
    inherit (config.services.rspamd) group;
  };

  security.acme = {
    acceptTerms = true;
    certs.${address} = {
      webroot = "/var/lib/acme/acme-challenge";
      email = "steamykins@gmail.com";
    };
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      25 # Inbound mail
      465 # Secure SMTP for inbound clients
      587 # SMTP outbound (submission)
      # 143 # IMAP
      # 993 # IMAP TLS/SSL
    ];
  };

  systemd.services = let
    sharedCredentials = {
      requires = [ "acme-finished-${address}.target" ];
      serviceConfig.LoadCredential = let
        acmeDir = config.security.acme.certs.${address}.directory;
      in [
        "fullchain.pem:${acmeDir}/fullchain.pem"
        "key.pem:${acmeDir}/key.pem"
      ];
    };
  in {
    opensmtpd = sharedCredentials // { wants = [ "rspamd.service" "dovecot2.service" ]; };
    dovecot2 = sharedCredentials;
    rspamd = {
      serviceConfig.LoadCredential = [
        "dkim.key:${config.sops.secrets.dkim.path}"
      ];
    };
  };

  # https://prefetch.eu/blog/2020/email-server/
  services.opensmtpd = {
    enable = true;

    setSendmail = false;
    serverConfiguration = ''
      # Set up the certificates
      pki ${mailAddress} cert "/run/credentials/opensmtpd.service/fullchain.pem"
      pki ${mailAddress} key "/run/credentials/opensmtpd.service/key.pem"

      # Spam filter directives
      filter "rdns" phase connect match !rdns disconnect "550 Error: no rDNS"
      filter "fcrdns" phase connect match !fcrdns disconnect "550 Error: no FCrDNS"
      filter "senderscore" proc-exec "${(pkgs.callPackage ./opensmtpd-filter-senderscore.nix {})}/bin/filter-senderscore filter-senderscore -junkBelow 70 -slowFactor 5000"
      filter "rspamd" proc-exec "${pkgs.opensmtpd-filter-rspamd}/bin/filter-rspamd"

      # Inbound/outbound mail receiving/sending
      listen on 0.0.0.0 tls pki ${mailAddress} auth-optional filter { "rdns", "fcrdns", "senderscore", "rspamd" } hostname ${mailAddress}
      listen on 0.0.0.0 smtps pki "${mailAddress}" auth filter "rspamd" hostname ${mailAddress}
      listen on 0.0.0.0 port submission tls-require pki "${mailAddress}" auth filter "rspamd" hostname ${mailAddress}

      # Inbound/outbound mail handling
      action "inbound" maildir junk
      action "outbound" relay helo ${mailAddress}
      
      match from local for local action "inbound"
      match from any for domain "${mailAddress}" action "inbound"

      match from any for any action "outbound"
    '';

    procPackages = with pkgs; [
      (callPackage ./opensmtpd-filter-senderscore.nix {})
      opensmtpd-filter-rspamd
    ];
  };

  services.rspamd = {
    enable = true;

    locals = {
      "dkim_signing.conf".text = ''
        allow_username_mismatch = true;

        domain {
          ${address} {
            path = "/run/credentials/rspamd.service/dkim.key";
            selector = "s1";
          }
        }
      '';
      
      "clamav_filter.conf".text = ''
        clamav {
          action = "reject";
          message = '''''${SCANNER}: virus found: "''${VIRUS}"';
          scan_mime_parts = true;
          scan_image_mime = false;
          symbol = "CLAM_VIRUS";
          type = "clamav";
          prefix = "rs_cl_";
          servers = "${config.services.clamav.daemon.settings.LocalSocket}";
        }
      '';
    };
  };

  services.clamav = {
    daemon.enable = true;

    updater = {
      enable = true;

      frequency = 12;
      interval = "hourly";
    };
  };

  services.dovecot2 = {
    enable = true;
    enableImap = true;
    
    enablePAM = true;
    showPAMFailure = true;

    mailLocation = "maildir:/var/mail/%u";

    sslServerCert = "/run/credentials/dovecot2.service/fullchain.pem";
    sslServerKey = "/run/credentials/dovecot2.service/key.pem";

    mailboxes = {
      Spam = {
        specialUse = "Junk";
        auto = "create";
      };
    };

    extraConfig = ''
      ssl_min_protocol = TLSv1.2
      ssl_prefer_server_ciphers = yes
    '';
  };

  # https://linderud.dev/blog/pam-bypass-when-nullis-notok/
  security.pam.services.dovecot2.text = let
    allowedGroups = pkgs.writeText "allowed_usermail_groups.allow" "${config.users.groups.mail_user.name}";
  in ''
    auth requisite pam_listfile.so onerr=fail item=group sense=allow file=${allowedGroups}
    auth required pam_unix.so
    account required pam_unix.so
    password required pam_unix.so
    session required pam_unix.so
  '';

  users = {
    groups.mail_user = { };
    users = {
      testNOTAREALUSER = {
        isSystemUser = true;
        description = "Test Mail User";
        group = "mail_user";
        shell = pkgs.shadow;
        initialPassword = "password";
      };
    };
  };
}
