{ config, ... }:

{
  # NOTE: Consider moving to trustless content-addressed derivations:
  # https://github.com/NixOS/nix/issues/2789#issuecomment-595143352
  nix.settings.trusted-users = [ "nixbld-remote" ];

  users = {
    groups.nixbld-remote = { };
    users.nixbld-remote = {
      description = "Nix build user (remote)";
      isNormalUser = true;
      home = "/tmp/nixbld-remote";
      group = config.users.groups.nixbld-remote.name;
      openssh.authorizedKeys.keyFiles = [
        ../venus/ssh_nixbld-remote_ed25519_key.pub
      ];
    };
  };
}
