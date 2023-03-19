{ pkgs, ... }:

{
  # Can't include the .conf contents into the NixOS format,
  # because the `control` field in the node isn't the last field in the
  # generated JSON object anymore, and PipeWire can't create the graph:
  # https://github.com/werman/noise-suppression-for-voice/issues/62
  # https://gitlab.freedesktop.org/pipewire/pipewire/-/issues/1526
  systemd.user.services.pipewire-hifiman-sundara-eq = {
    description = "PipeWire HIFIMAN Sundara Equalized sink";
    after = [ "pipewire.service" ];
    wantedBy = [ "graphical-session-pre.target" ];

    serviceConfig.ExecStart = "${pkgs.pipewire}/bin/pipewire -c ${./equalizer.conf}";
  };

  systemd.user.services.wireplumber-volume = {
    description = "PipeWire set default volume to 100%";
    after = [
      "wireplumber.service"
      "pipewire-hifiman-sundara-eq.service"
      "pipewire-rnnoise.service"
      "wireplumber-default-nodes.service"
    ];
    wantedBy = [ "graphical-session-pre.target" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.wireplumber}/bin/wpexec ${./volume.lua}";
    };
  };

  systemd.user.services.wireplumber-default-nodes = {
    description = "PipeWire set default audio sink, source";
    after = [
      "wireplumber.service"
      "pipewire-hifiman-sundara-eq.service"
      "pipewire-rnnoise.service"
    ];
    wantedBy = [ "graphical-session-pre.target" ];

    serviceConfig.Type = "oneshot";
    script = ''
      status="$(${pkgs.wireplumber}/bin/wpctl status)"

      # Set default sink/source to the correct nodes.
      # Note that it would be more correct to match between 'Sinks: and
      # 'Sink endpoints:' lines, but it seems to work fine for now.
      sink="$(echo "$status" | ${pkgs.gnused}/bin/sed -n 's/[ │*]\+\([0-9]\+\)\. HIFIMAN Sundara (Equalized).*/\1/p')"
      source=$(echo "$status" | ${pkgs.gnused}/bin/sed -n 's/[ │*]\+\([0-9]\+\)\. Noise Cancelling source.*/\1/p')
      ${pkgs.wireplumber}/bin/wpctl set-default "$sink"
      ${pkgs.wireplumber}/bin/wpctl set-default "$source"
    '';
  };

  environment.etc."wireplumber/main.lua.d/51-disable-devices-nodes.lua".text = ''
    local disable_devices = {
      matches = {
        -- GPU HDMI audio.
        {{ "device.name", "equals", "alsa_card.pci-0000_03_00.1" }},
      },
      apply_properties = {
        ["device.disabled"] = true,
      },
    }

    local disable_nodes = {
      matches = {
        -- Microphone.
        -- In recent updates, even though this isn't the default device, audio
        -- is routed from headphones to microphone instead of the DAC. Why?
        {{ "node.name", "equals", "alsa_output.usb-FIFINE_Microphones_Fifine_K658_Microphone_REV1.0-00.analog-stereo" }},
      },
      apply_properties = {
        ["node.disabled"] = true,
      },
    }

    table.insert(alsa_monitor.rules, disable_devices)
    table.insert(alsa_monitor.rules, disable_nodes)
  '';

  environment.etc."wireplumber/main.lua.d/51-usb-audio.lua".text = ''
    -- USB audio interfaces can take a while to wake up from suspending.
    table.insert(alsa_monitor.rules, {
      matches = {
        {{ "node.name", "matches", "alsa_*.usb-*" }}
      },
      apply_properties = {
        ["session.suspend-timeout-seconds"] = 0,
      },
    })
  '';
}
