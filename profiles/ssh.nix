{ config, lib, ... }:

{
  preservation.preserveAt."/persist/state".files = [
    { file = "/etc/ssh/ssh_host_ed25519_key"; mode = "0600"; how = "symlink"; configureParent = true; parent.mode = "0755"; }
    { file = "/etc/ssh/ssh_host_ed25519_key.pub"; mode = "0644"; how = "symlink"; configureParent = true; parent.mode = "0755"; }
  ];

  services.openssh = {
    enable = true;

    ports = [ 3101 ];
    startWhenNeeded = true;
    authorizedKeysInHomedir = false;

    # The host key should be considered state, as it can change, and we may
    # want to be informed of changes.
    hostKeys = [
      {
        # Unfortunately, sshd-keygen.service fails to generate the host keys
        # when this is managed with the preservation module - neither bind
        # mounts nor symlinks work. We generate the host key in
        # /persist/state/etc/ssh directly.
        path = (lib.optionalString config.preservation.enable "/persist/state") + "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];

    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;

      KexAlgorithms = [
        "mlkem768x25519-sha256"
        "sntrup761x25519-sha512"
        "curve25519-sha256@libssh.org"
        "diffie-hellman-group-exchange-sha256"
      ];

      Ciphers = [
        # aes256-gcm and aes128-gcm should often offer much better performance than
        # chacha20-poly1305.
        "aes256-gcm@openssh.com"
        "aes128-gcm@openssh.com"
        "chacha20-poly1305@openssh.com"
        "aes256-ctr"
        "aes192-ctr"
        "aes128-ctr"
      ];

      Macs = [
        "hmac-sha2-512-etm@openssh.com"
        "hmac-sha2-256-etm@openssh.com"
        "umac-128-etm@openssh.com"
        "hmac-sha2-512"
        "hmac-sha2-256"
        "umac-128@openssh.com"
      ];
    };
  };
}
