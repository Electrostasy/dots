{ config, lib, ... }:

{
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
    knownHosts = lib.pipe ../../hosts [
      # List all the defined hosts.
      builtins.readDir

      # Assume they have a publicKeyFile in their directory.
      (lib.mapAttrs (name: _: {
        publicKeyFile = ../../hosts/${name}/ssh_host_ed25519_key.pub;
      }))

      # Filter for other hosts that do have a real publicKeyFile.
      (lib.filterAttrs (name: value:
        name != config.networking.hostName && builtins.pathExists value.publicKeyFile))
    ];

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
