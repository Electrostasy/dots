{ config, pkgs, ... }:

{
  imports = [ ./container.nix ];

  hardware.opengl = {
    driSupport32Bit = true;
    extraPackages = [ pkgs.amdvlk ];
    extraPackages32 = [ pkgs.driversi686Linux.amdvlk ];
  };

  nixpkgs.allowedUnfreePackages = with pkgs; [
    steam
    steam-run
    steamPackages.steam
    steamPackages.steam-runtime
  ];
}
