{ config, pkgs, ... }:

{
  # Can't include the .conf contents into the NixOS format,
  # because the `control` field in the node isn't the last field in the
  # generated JSON object anymore, and PipeWire can't create the graph:
  # https://github.com/werman/noise-suppression-for-voice/issues/62
  # https://gitlab.freedesktop.org/pipewire/pipewire/-/issues/1526
  systemd.user.services.pipewire-hifiman-sundara-eq = {
    enable = true;
    description = "PipeWire HIFIMAN Sundara Equalized sink";
    after = [ "pipewire.service" ];
    bindsTo = [ "pipewire.service" ];
    wantedBy = [ "pipewire.service" ];
    serviceConfig = {
      ExecStart = "${pkgs.pipewire}/bin/pipewire -c ${
        pkgs.writeText "pipewire-sundara-eq.conf" (builtins.readFile ./equalizer.conf)
      }";
    };
  };
}
