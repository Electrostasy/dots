{ pkgs, ... }:

{
  imports = [ ./noise-suppression.nix ];

  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;

    pulse.enable = true;
    alsa.enable = true;
  };

  environment.etc."wireplumber/main.lua.d/51-midi.lua".text = ''
    alsa_monitor.properties = {
      ["alsa.midi"] = false,
      ["alsa.midi.monitoring"] = false,
    }
  '';
}
