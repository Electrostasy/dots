{ config, pkgs, ... }:

{
  imports = [
    ./noise-suppression.nix
    ./equalizer.nix
  ];

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
  };
}
