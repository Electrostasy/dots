{ config, lib, ... }:

{
  environment.persistence.state.files = [
    "/etc/ssh/ssh_host_ed25519_key"
    "/etc/ssh/ssh_host_ed25519_key.pub"
  ];

  services.openssh = {
    enable = lib.mkDefault true;

    ports = [ 3101 ];

    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;

      KexAlgorithms = [
        "curve25519-sha256@libssh.org"
        "diffie-hellman-group-exchange-sha256"
      ];

      Ciphers = [
        "chacha20-poly1305@openssh.com"
        "aes256-gcm@openssh.com"
        "aes128-gcm@openssh.com"
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

  programs.ssh = let sshdConfig = config.services.openssh.settings; in {
    knownHosts = lib.filterAttrs (n: _: n != config.networking.hostName) {
      kepler.publicKeyFile = ../../hosts/kepler/ssh_host_ed25519_key.pub;
      luna.publicKeyFile = ../../hosts/luna/ssh_host_ed25519_key.pub;
      mars.publicKeyFile = ../../hosts/mars/ssh_host_ed25519_key.pub;
      mercury.publicKeyFile = ../../hosts/mercury/ssh_host_ed25519_key.pub;
      phobos.publicKeyFile = ../../hosts/phobos/ssh_host_ed25519_key.pub;
      terra.publicKeyFile = ../../hosts/terra/ssh_host_ed25519_key.pub;
      venus.publicKeyFile = ../../hosts/venus/ssh_host_ed25519_key.pub;
    };

    kexAlgorithms = sshdConfig.KexAlgorithms;
    ciphers = sshdConfig.Ciphers;
    macs = sshdConfig.Macs;
    hostKeyAlgorithms = [
      "ssh-ed25519-cert-v01@openssh.com"
      "ssh-rsa-cert-v01@openssh.com"
      "ssh-ed25519"
      "ssh-rsa"
    ];

    # Generate a new private/public key/pair:
    # $ ssh-keygen -t ed25519 -a 32 -f key -N '' -C "$USER@$HOST"
    extraConfig = ''
      Host *
        PasswordAuthentication no
        KbdInteractiveAuthentication no
        PubkeyAuthentication yes

      Match exec "host %h | grep 'sol.${config.networking.domain}'"
        Port 3101
        UserKnownHostsFile /etc/ssh/ssh_known_hosts
        ${
          let
            identities =
              lib.filterAttrs
                (name: _: lib.hasSuffix "Identity" name)
                config.sops.secrets;
          in
            lib.concatStringsSep
              "\n"
              (lib.mapAttrsToList (_: v: "IdentityFile ${v.path}") identities)
        }
    '';
  };
}
