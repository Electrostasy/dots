{ config, pkgs, lib, ... }:

{
  config = lib.mkIf (config.sops.secrets != { }) {
    preservation.preserveAt."/persist/state".directories = [
      { directory = builtins.dirOf config.sops.age.keyFile; inInitrd = true; }
    ];

    # This is required for `nixos-rebuild build-vm` to work correctly.
    virtualisation.vmVariant = {
      virtualisation.sharedDirectories.sops = {
        source = builtins.dirOf config.sops.age.keyFile;
        target = builtins.dirOf config.sops.age.keyFile;
      };
    };

    sops = {
      age = {
        keyFile = "/var/lib/sops-nix/keys.txt";
        sshKeyPaths = [];
      };
      gnupg.sshKeyPaths = [];
    };

    environment = {
      sessionVariables.SOPS_AGE_KEY_FILE = config.sops.age.keyFile;

      systemPackages = with pkgs; [
        rage
        sops
      ];
    };
  };
}
