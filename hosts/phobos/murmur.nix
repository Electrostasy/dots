{ config, ... }:

{
  sops.secrets.murmurEnv = { };

  preservation.preserveAt."/persist/state".directories = [ config.services.murmur.stateDir ];

  security.acme.certs."0x6776.lt".postRun = ''
    systemctl --no-block restart murmur
  '';

  services.murmur = {
    enable = true;

    environmentFile = "${config.sops.secrets.murmurEnv.path}";
    password = "$PASSWORD";

    port = 64738;
    openFirewall = true;

    tls = {
      certPath = "/run/credentials/murmur.service/cert.pem";
      caPath = "/run/credentials/murmur.service/chain.pem";
      keyPath = "/run/credentials/murmur.service/key.pem";
    };
  };

  systemd.services.murmur.serviceConfig.LoadCredential = [
    "cert.pem:${config.security.acme.certs."0x6776.lt".directory}/cert.pem"
    "chain.pem:${config.security.acme.certs."0x6776.lt".directory}/chain.pem"
    "key.pem:${config.security.acme.certs."0x6776.lt".directory}/key.pem"
  ];
}
