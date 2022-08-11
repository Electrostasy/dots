{ config, ... }:

{
  # Generate a new key-pair using command:
  # $ ssh-keygen -t ed25519 -a 100 -f ./nixbld-remote-key -C nixbld-remote@terra.local
  sops.secrets.sshNixbldRemoteKey = {
    mode = "0700";
    owner = config.users.users.root.name;
    inherit (config.users.users.root) group;
  };

  nix = {
    distributedBuilds = true;
    settings.builders-use-substitutes = true;

    buildMachines = [
      { hostName = "terra.local";
        system = "x86_64-linux";
        maxJobs = 4;
        speedFactor = 1;
        supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
        sshUser = "nixbld-remote";
        sshKey = config.sops.secrets.sshNixbldRemoteKey.path;
      }
    ];
  };
}
