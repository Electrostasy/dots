{ config, pkgs, lib, self, ... }:

let
  keyFile = "/var/lib/sops-nix/keys.txt";
in

{
  imports = [ self.inputs.sops-nix.nixosModules.default ];
} // lib.mkIf (config.sops.secrets != { }) {
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
}
