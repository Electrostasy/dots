{ config, pkgs, lib, ... }:

{
  services.dbus.enable = true;

  nixpkgs.allowedUnfreePackages = with pkgs; [
    steam
    steam-run
    steamPackages.steam
    steamPackages.steam-runtime
  ];

  programs.steam.enable = true;

  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  users.users.steam = {
    isNormalUser = true;
    initialPassword = "steam";
    extraGroups = [ "wheel" ];
  };
}

