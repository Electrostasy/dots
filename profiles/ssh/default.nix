# Generate a new private/public ssh keypair:
# $ ssh-keygen -t ed25519 -a 32 -f key -N '' -C "$USER@$HOST"

{ config, lib, ... }:

let
  mkHostKey = name: value:
    { type = "ed25519"; path = value.path; };

  mkIdentityFile = name: value:
    "IdentityFile ${value.path}";

  identities =
    lib.filterAttrs
      (name: _: lib.hasSuffix "Identity" name)
      config.sops.secrets;
in

{
  imports = [ ./hardening.nix ];

  services.openssh = {
    enable = true;

    ports = [ 3101 ];

    # Don't run sshd all the time.
    startWhenNeeded = true;

    # `sshd` will quit on startup if we do not have any host keys defined,
    # but we do not need them, so we will reuse our user identities.
    hostKeys = lib.mapAttrsToList mkHostKey identities;
  };

  programs.ssh = {
    # Add all the hosts except the host importing this config to the
    # /etc/ssh/ssh_known_hosts file. This will prevent `sshd` from asking
    # connecting clients about the host's fingerprint.
    knownHosts =
      let
        isRealKey = name: value:
          name != config.networking.hostName && builtins.pathExists value.publicKeyFile;

        potentialKeys =
          lib.mapAttrs
            (name: _: { publicKeyFile = ../../hosts/${name}/id_ed25519.pub; })
            (builtins.readDir ../../hosts);
      in
        lib.filterAttrs isRealKey potentialKeys;

    extraConfig = ''
      # gzip is used for compression, which is relatively slow, so on fast
      # networks it can be a bottleneck.
      Compression no

      Match exec "host %h | grep 'sol.tailnet.${config.networking.domain}'"
        Port 3101
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList mkIdentityFile identities)}

        # I do not use IPv6 so this can speed up login time a bit.
        AddressFamily inet
    '';
  };
}
