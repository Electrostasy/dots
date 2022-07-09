{
  nix.settings.trusted-users = [ "nixbld-remote" ];
  users.users.nixbld-remote = {
    isSystemUser = true;
    group = "nixbld";
    extraGroups = [ "nixbld" ];
    openssh.authorizedKeys.keyFiles = [
      ../deimos/ssh_root_ed25519_key.pub
    ];
  };
}
