{ config, pkgs, lib, ... }:

{
  imports = [ ./cuda-wsl.nix ];

  system.stateVersion = "22.05";

  wsl = {
    enable = true;
    automountPath = "/mnt";
    defaultUser = "nixos";
    startMenuLaunchers = false;
  };

  users.users.${config.wsl.defaultUser}.shell = pkgs.fish;
}
