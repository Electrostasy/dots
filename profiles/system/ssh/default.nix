{ config, lib, ... }:

{
  services.openssh = {
    enable = true;

    permitRootLogin = "no";
    passwordAuthentication = false;
    kbdInteractiveAuthentication = false;
  };

  # Ensure that all other hosts know each other when connecting by ssh.
  programs.ssh.knownHosts = lib.filterAttrs (n: _: n != config.networking.hostName) {
    deimos.publicKeyFile = ../../../hosts/deimos/ssh_root_ed25519_key.pub;
    jupiter.publicKeyFile = ../../../hosts/jupiter/ssh_root_ed25519_key.pub;
    kepler.publicKeyFile = ../../../hosts/kepler/ssh_root_ed25519_key.pub;
    phobos.publicKeyFile = ../../../hosts/phobos/ssh_root_ed25519_key.pub;
    terra.publicKeyFile = ../../../hosts/terra/ssh_root_ed25519_key.pub;
    venus.publicKeyFile = ../../../hosts/venus/ssh_electro_ed25519_key.pub;
  };
}
