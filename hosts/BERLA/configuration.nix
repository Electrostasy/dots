{ config, pkgs, lib, ... }:

{
  system.stateVersion = "22.05";

  wsl = {
    enable = true;
    automountPath = "/mnt";
    defaultUser = "nixos";
    startMenuLaunchers = false;
  };

  users.users.nixos.shell = pkgs.fish;
}
