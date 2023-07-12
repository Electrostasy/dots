{ config, lib, ... }:

{
  services.openssh = {
    enable = true;

    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  # Ensure that all other hosts know each other when connecting by ssh.
  programs.ssh.knownHosts = lib.filterAttrs (n: _: n != config.networking.hostName) {
    kepler.publicKeyFile = ../../../hosts/kepler/ssh_root_ed25519_key.pub;
    phobos.publicKeyFile = ../../../hosts/phobos/ssh_root_ed25519_key.pub;
    terra.publicKeyFile = ../../../hosts/terra/ssh_root_ed25519_key.pub;
    venus.publicKeyFile = ../../../hosts/venus/ssh_electro_ed25519_key.pub;
  };
}
