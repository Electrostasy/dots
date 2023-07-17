{ config, lib, ... }:

{
  services.openssh = {
    enable = true;

    ports = [ 3101 ];

    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;

      KexAlgorithms = [
        "curve25519-sha256@libssh.org"
        "diffie-hellman-group-exchange-sha256"
        "ecdh-sha2-nistp256"
        "ecdh-sha2-nistp384"
        "ecdh-sha2-nistp521"
      ];
      Ciphers = [
        "aes128-ctr"
        "aes128-gcm@openssh.com"
        "aes192-ctr"
        "aes256-ctr"
        "aes256-gcm@openssh.com"
        "chacha20-poly1305@openssh.com"
      ];
      Macs = [
        "hmac-sha2-256"
        "hmac-sha2-256-etm@openssh.com"
        "hmac-sha2-512"
        "hmac-sha2-512-etm@openssh.com"
        "umac-128-etm@openssh.com"
        "umac-128@openssh.com"
      ];
    };
  };

  programs.ssh.knownHosts = lib.filterAttrs (n: _: n != config.networking.hostName) {
    kepler.publicKeyFile = ../../../hosts/kepler/ssh_root_ed25519_key.pub;
    phobos.publicKeyFile = ../../../hosts/phobos/ssh_root_ed25519_key.pub;
    terra.publicKeyFile = ../../../hosts/terra/ssh_root_ed25519_key.pub;
    venus.publicKeyFile = ../../../hosts/venus/ssh_electro_ed25519_key.pub;
  };
}
