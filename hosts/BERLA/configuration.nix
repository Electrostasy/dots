{ config, pkgs, lib, ... }:

{
  wsl = {
    enable = true;
    automountPath = "/mnt";
    defaultUser = "nixos";
    startMenuLaunchers = false;
  };

  users.users.nixos.shell = pkgs.fish;
}
