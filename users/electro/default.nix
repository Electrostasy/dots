{ config, ... }:

{
  sops.secrets = {
    # The user has the same hashed password across all hosts.
    electroPassword = {
      sopsFile = ./secrets.yaml;
      neededForUsers = true;
    };

    # The user's ssh private key has to be unique to every host, configured in
    # the per-host sops.defaultSopsFile option.
    electroIdentity = {
      mode = "0400";
      owner = config.users.users.electro.name;
    };
  };

  preservation.preserveAt."/persist/state".users.electro.files = [
    { file = ".ssh/known_hosts"; mode = "0644"; parent.mode = "0700"; }
  ];

  users.users.electro = {
    isNormalUser = true;
    uid = 1000;
    hashedPasswordFile = config.sops.secrets.electroPassword.path;
    extraGroups = [ "wheel" ];

    openssh.authorizedKeys.keyFiles = [
      ../../hosts/mercury/id_ed25519.pub
      ../../hosts/terra/id_ed25519.pub
      ../../hosts/venus/id_ed25519.pub
    ];
  };

  programs.ssh.extraConfig = ''
    Match user ${config.users.users.electro.name}
      IdentityFile ${config.sops.secrets.electroIdentity.path}
  '';
}
