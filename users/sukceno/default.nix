{ config, ... }:

{
  sops.secrets.sukcenoPassword = {
    sopsFile = ./secrets.yaml;
    neededForUsers = true;
  };

  users.users.sukceno = {
    isNormalUser = true;
    uid = 1001;

    hashedPasswordFile = config.sops.secrets.sukcenoPassword.path;
  };
}
