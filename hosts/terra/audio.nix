{ config, pkgs, lib, ... }:

{
  # Use WirePlumber rules to disable S/PDIF and other unused sources/sinks.
  environment.etc."wireplumber/main.lua.d/60-custom-alsa.lua".source = ./wp-alsa-rules.lua;

  # Use WirePlumber `wpexec` script to set default volume and default nodes, as
  # it overrides `default.configured.audio.{sink,source}` from PipeWire's
  # `context.properties`.
  systemd.user.services.wireplumber-defaults = {
    description = "WirePlumber set default volume and nodes";
    after = [ "wireplumber.service" ];
    wantedBy = [ "graphical-session-pre.target" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${config.services.pipewire.wireplumber.package}/bin/wpexec ${./wpexec-defaults.lua}";
    };
  };

  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    pulse.enable = true;

    # EQ for HIFIMAN Sundara headphones based on 10 band parametric EQ from:
    # https://github.com/jaakkopasanen/AutoEq/tree/master/results/oratory1990
    extraConfig.pipewire."60-hifiman-sundara" = {
      "context.modules" = [
        { name = "libpipewire-module-rtkit"; args = { }; flags = [ "ifexists" "nofail" ]; }
        { name = "libpipewire-module-filter-chain";
          args = {
            "node.description" = "HIFIMAN Sundara";
            "media.name" = "HIFIMAN Sundara";
            "filter.graph" =
              let
                # Gain is calculated as pow(10, db/20).
                nodes = [
                  {
                    type = "builtin";
                    name = "mixerI";
                    label = "mixer";
                    control = { "Gain 1" = 0.457088; };
                  }
                  {
                    type = "builtin";
                    name = "eq_1";
                    label = "bq_lowshelf";
                    control = { "Freq" = 105.0; "Q" = 0.7; "Gain" = 1.496236; };
                  }
                  {
                    type = "builtin";
                    name = "eq_2";
                    label = "bq_peaking";
                    control = { "Freq" = 197.0; "Q" = 0.18; "Gain" = 0.860994; };
                  }
                  {
                    type = "builtin";
                    name = "eq_3";
                    label = "bq_peaking";
                    control = { "Freq" = 1950.0; "Q" = 1.84; "Gain" = 2.113489; };
                  }
                  {
                    type = "builtin";
                    name = "eq_4";
                    label = "bq_peaking";
                    control = { "Freq" = 3797.0; "Q" = 1.05; "Gain" = 0.595662; };
                  }
                  {
                    type = "builtin";
                    name = "eq_5";
                    label = "bq_peaking";
                    control = { "Freq" = 6109.0; "Q" = 3.33; "Gain" = 1.798871; };
                  }
                  {
                    type = "builtin";
                    name = "eq_6";
                    label = "bq_peaking";
                    control = { "Freq" = 71.0; "Q" = 1.84; "Gain" = 0.944061; };
                  }
                  {
                    type = "builtin";
                    name = "eq_7";
                    label = "bq_peaking";
                    control = { "Freq" = 458.0; "Q" = 2.9; "Gain" = 1.148154; };
                  }
                  {
                    type = "builtin";
                    name = "eq_8";
                    label = "bq_peaking";
                    control = { "Freq" = 824.0; "Q" = 2.49; "Gain" = 0.891251; };
                  }
                  {
                    type = "builtin";
                    name = "eq_9";
                    label = "bq_peaking";
                    control = { "Freq" = 9193.0; "Q" = 2.74; "Gain" = 1.513561; };
                  }
                  {
                    type = "builtin";
                    name = "eq_10";
                    label = "bq_highshelf";
                    control = { "Freq" = 10000.0; "Q" = 0.7; "Gain" = 0.616595; };
                  }
                ];
              in
              {
                inherit nodes;

                inputs = [ "mixerI:In 1" ];
                outputs = [ "eq_10:Out" ];

                links =
                  lib.zipListsWith
                    (outNode: inNode: {
                      input = "${inNode.name}:In";
                      output = "${outNode.name}:Out";
                    })
                    (lib.init nodes)
                    (lib.tail nodes);
              };

            "audio.channels" = 2;
            "audio.position" = [ "FL" "FR" ];

            "capture.props" = {
              "node.name" = "hifiman_sundara_input";
              "media.class" = "Audio/Sink";
            };

            "playback.props" = {
              "node.name" = "hifiman_sundara_output";
              "node.passive" = true;
            };
          };
        }
      ];
    };

    # RNNoise Noise Cancelling Source for microphone:
    # https://github.com/werman/noise-suppression-for-voice
    extraConfig.pipewire."60-microphone-rnnoise" = {
      "context.modules" = [
        { name = "libpipewire-module-filter-chain";
          args = {
            "node.description" = "Microphone (noise suppressed)";
            "media.name" = "Microphone (noise suppressed)";
            "filter.graph" = {
              nodes = [
                {
                  type = "ladspa";
                  name = "rnnoise";
                  plugin = "${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so";
                  label = "noise_suppressor_mono";
                  control = {
                    "VAD Threshold (%)" = 85.0;
                    "VAD Grace Period (ms)" = 500;
                    "Retroactive VAD Grace (ms)" = 0;
                  };
                }
              ];
            };
            "audio.rate" = 48000;
            "audio.position" = [ "FL" ];
            "capture.props" = {
              "node.passive" = true;
              "node.name" = "rnnoise_input";
            };
            "playback.props" = {
              "media.class" = "Audio/Source";
              "node.name" = "rnnoise_output";
            };
          };
        }
      ];
    };

    # Configure pipewire for low latency (fixes audio crackling).
    extraConfig.pipewire."92-low-latency" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 32;
        "default.clock.min-quantum" = 16;
        "default.clock.max-quantum" = 768;
      };
    };

    # Configure pipewire-pulse for low latency (fixes audio crackling in some
    # games):
    # https://docs.pipewire.org/page_module_protocol_pulse.html
    extraConfig.pipewire-pulse = {
      "92-low-latency" = {
        "pulse.properties" = {
          "pulse.default.req" = "32/48000";
          "pulse.min.req" = "16/48000";
          "pulse.max.req" = "768/48000";
          "pulse.min.quantum" = "16/48000";
          "pulse.max.quantum" = "768/48000";
        };

        "stream.properties" = {
          "node.latency" = "32/48000";
          "resample.quality" = 1;
        };
      };
    };
  };
}
