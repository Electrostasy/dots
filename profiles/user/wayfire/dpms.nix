{ pkgs, lib, ... }:

let
  dpms = pkgs.writeShellApplication {
    name = "dpms";
    runtimeInputs = with pkgs; [
      wlopm
      coreutils
    ];
    text = ''
      wlopm | cut -d' ' -f1 | while read -r o; do wlopm "--$1 $o"; done
    '';
  };
in

{
  services.swayidle = {
    enable = true;

    systemdTarget = "wayfire-session.target";
    timeouts = lib.singleton {
      # After 5 minutes of inactivity, turn off the outputs, and upon activity,
      # turn them back on.
      timeout = 60 * 5;
      command = "${dpms}/bin/dpms off";
      resumeCommand = "${dpms}/bin/dpms on";
    };

    events = lib.singleton {
      # If outputs are off and the machine is suspended, the outputs will stay
      # off until the machine is interacted with again. Before suspend, turn on
      # the outputs, so that when woken up, they will already be on.
      event = "before-sleep";
      command = "${dpms}/bin/dpms on";
    };
  };

  # Restore toplevels to their original positions, geometry and z-order after
  # DPMS if outputs are temporarily disconnected.
  wayland.windowManager.wayfire.settings.plugins = [
    { plugin = "preserve-output"; }
  ];
}
