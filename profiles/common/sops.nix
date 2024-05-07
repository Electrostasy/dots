{ config, pkgs, lib, self, ... }:

let
  keyFile = "/var/lib/sops-nix/keys.txt";
in

{
  imports = [ self.inputs.sops-nix.nixosModules.default ];

  config = lib.mkIf (config.sops.secrets != { }) {
    # This is required for `nixos-rebuild build-vm` to work correctly.
    virtualisation.vmVariant = {
      virtualisation.sharedDirectories.sops = {
        source = builtins.dirOf keyFile;
        target = builtins.dirOf keyFile;
      };
    };

    sops = {
      age = {
        inherit keyFile;
        sshKeyPaths = [];
      };
      gnupg.sshKeyPaths = [];
    };

    environment = {
      sessionVariables.SOPS_AGE_KEY_FILE = keyFile;

      systemPackages = with pkgs; [
        rage
        sops
      ];
    };
  };
}
