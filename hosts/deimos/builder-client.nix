{ config, ... }:

{
  sops.secrets.sshHostKey = { };

  nix = {
    maxJobs = 0; # force remote building
    distributedBuilds = true;
    buildMachines = [{
      hostName = "phobos.local";
      system = "aarch64-linux";
      sshUser = "nixbld-remote";
      sshKey = config.sops.secrets.sshHostKey.path;
      maxJobs = 4;
      speedFactor = 2;
      supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
    }];
  };
}
