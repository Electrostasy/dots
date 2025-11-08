{ pkgs, ... }:

let
  sofa = pkgs.fetchurl {
    url = "https://sofacoustics.org/data/database/clubfritz/ClubFritz4.sofa";
    hash = "sha256-V6rFKb+MycLFHemw6bUGLB1odugqKiMMErAizudZsHY=";
  };
in

{
  preservation.preserveAt."/persist/state".users.electro.directories = [
    ".local/state/wireplumber"
  ];

  # mpv cannot play multichannel audio with the "default" device due to ALSA:
  # https://github.com/mpv-player/mpv/commit/af3bbb800d709f81c9f30bc4ced26c98ea5eafd6
  programs.mpv.settings.surround_7_1 = {
    profile-desc = "Choose 7.1 Surround audio device";
    profile-cond = "audio_params[\"channel-count\"] > 2";
    profile-restore = "copy";
    audio-device = "pipewire/input.7_1_spatializer";
  };

  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    pulse.enable = true;

    extraConfig.pipewire = {
      "60-parametric-equalizer" = {
        "context.modules" = [
          { name = "libpipewire-module-rtkit"; args = { }; flags = [ "ifexists" "nofail" ]; }

          # https://github.com/jaakkopasanen/AutoEq/tree/master/results/oratory1990.
          {
            name = "libpipewire-module-parametric-equalizer";
            args = {
              "node.description" = "HIFIMAN Sundara";
              "media.name" = "HIFIMAN Sundara";
              "equalizer.filepath" = ./HIFIMAN-Sundara-Dekoni-sheepskin-Earpads-ParametricEQ.txt;
              "equalizer.description" = "Parametric Equalizer sink for HIFIMAN Sundara headphones";
              "audio.channels" = 2;
              "audio.position" = [ "FL" "FR" ];

              "capture.props" = {
                "node.name" = "input.hifiman_sundara_eq";
              };

              "playback.props" = {
                "node.name" = "output.hifiman_sundara_eq";
              };
            };
          }
          {
            name = "libpipewire-module-parametric-equalizer";
            args = {
              "node.description" = "HIFIMAN Sundara Closed-back";
              "media.name" = "HIFIMAN Sundara Closed-back";
              "equalizer.filepath" = ./HIFIMAN-Sundara-Closed-Back-ParametricEQ.txt;
              "equalizer.description" = "Parametric Equalizer sink for HIFIMAN Sundara Closed-back headphones";
              "audio.channels" = 2;
              "audio.position" = [ "FL" "FR" ];

              "capture.props" = {
                "node.name" = "input.hifiman_sundara_closed_back_eq";
              };

              "playback.props" = {
                "node.name" = "output.hifiman_sundara_closed_back_eq";
              };
            };
          }
        ];
      };

      "60-spatializer" = {
        "context.modules" = [
          { name = "libpipewire-module-rtkit"; args = { }; flags = [ "ifexists" "nofail" ]; }

          {
            name = "libpipewire-module-filter-chain";
            args = {
              "node.description" = "7.1 Surround Sound Spatializer";
              "media.name" = "7.1 Surround Sound Spatializer";
              "filter.graph" = {
                nodes = [
                  {
                    type = "sofa";
                    label = "spatializer";
                    name = "FL";
                    config.filename = "${sofa}";
                    control = { "Azimuth" = 30.0; "Elevation" = 0.0; "Radius" = 3.0; };
                  }
                  {
                    type = "sofa";
                    label = "spatializer";
                    name = "FR";
                    config.filename = "${sofa}";
                    control = { "Azimuth" = 330.0; "Elevation" = 0.0; "Radius" = 3.0; };
                  }
                  {
                    type = "sofa";
                    label = "spatializer";
                    name = "FC";
                    config.filename = "${sofa}";
                    control = { "Azimuth" = 0.0; "Elevation" = 0.0; "Radius" = 3.0; };
                  }
                  {
                    type = "sofa";
                    label = "spatializer";
                    name = "RL";
                    config.filename = "${sofa}";
                    control = { "Azimuth" = 150.0; "Elevation" = 0.0; "Radius" = 3.0; };
                  }
                  {
                    type = "sofa";
                    label = "spatializer";
                    name = "RR";
                    config.filename = "${sofa}";
                    control = { "Azimuth" = 210.0; "Elevation" = 0.0; "Radius" = 3.0; };
                  }
                  {
                    type = "sofa";
                    label = "spatializer";
                    name = "SL";
                    config.filename = "${sofa}";
                    control = { "Azimuth" = 90.0; "Elevation" = 0.0; "Radius" = 3.0; };
                  }
                  {
                    type = "sofa";
                    label = "spatializer";
                    name = "SR";
                    config.filename = "${sofa}";
                    control = { "Azimuth" = 270.0; "Elevation" = 0.0; "Radius" = 3.0; };
                  }
                  {
                    type = "sofa";
                    label = "spatializer";
                    name = "LFE";
                    config.filename = "${sofa}";
                    control = { "Azimuth" = 0.0; "Elevation" = -60.0; "Radius" = 3.0; };
                  }
                  { type = "builtin"; label = "mixer"; name = "mixerL"; }
                  { type = "builtin"; label = "mixer"; name = "mixerR"; }
                ];

                links = [
                  { output = "FL:Out L"; input = "mixerL:In 1"; }
                  { output = "FL:Out R"; input = "mixerR:In 1"; }
                  { output = "FR:Out L"; input = "mixerL:In 2"; }
                  { output = "FR:Out R"; input = "mixerR:In 2"; }
                  { output = "FC:Out L"; input = "mixerL:In 3"; }
                  { output = "FC:Out R"; input = "mixerR:In 3"; }
                  { output = "RL:Out L"; input = "mixerL:In 4"; }
                  { output = "RL:Out R"; input = "mixerR:In 4"; }
                  { output = "RR:Out L"; input = "mixerL:In 5"; }
                  { output = "RR:Out R"; input = "mixerR:In 5"; }
                  { output = "SL:Out R"; input = "mixerR:In 6"; }
                  { output = "SL:Out L"; input = "mixerL:In 6"; }
                  { output = "SR:Out R"; input = "mixerR:In 7"; }
                  { output = "SR:Out L"; input = "mixerL:In 7"; }
                  { output = "LFE:Out R"; input = "mixerR:In 8"; }
                  { output = "LFE:Out L"; input = "mixerL:In 8"; }
                ];

                inputs = [ "FL:In" "FR:In" "FC:In" "RL:In" "RR:In" "SL:In" "SR:In" "LFE:In" ];
                outputs = [ "mixerL:Out" "mixerR:Out" ];
              };

              "capture.props" = {
                "node.name" = "input.7_1_spatializer";
                "media.class" = "Audio/Sink";
                "audio.channels" = 8;
                "audio.position" = [ "FL" "FR" "FC" "LFE" "RL" "RR" "SL" "SR" ];
              };

              "playback.props" = {
                "node.name" = "output.7_1_spatializer";
                "node.passive" = true;
                "audio.channels" = 2;
                "audio.position" = [ "FL" "FR" ];
              };
            };
          }
        ];
      };

      "60-microphone-denoiser" = {
        "context.modules" = [
          { name = "libpipewire-module-rtkit"; args = { }; flags = [ "ifexists" "nofail" ]; }
          {
            name = "libpipewire-module-filter-chain";
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
                "node.name" = "input.microphone_rnnoise";
              };

              "playback.props" = {
                "media.class" = "Audio/Source";
                "node.name" = "output.microphone_rnnoise";
              };
            };
          }
        ];
      };
    };

    wireplumber.extraConfig = {
      "60-defaults" = {
        "wireplumber.settings" = {
          "device.routes.default-sink-volume" = 1.0;
        };
      };

      "60-disabled-devices" = {
        "monitor.alsa.rules" = [
          {
            matches = [
              { "device.product.name" = "Navi 21/23 HDMI/DP Audio Controller"; }
            ];
            actions = {
              update-props = {
                "device.disabled" = true;
              };
            };
          }
          {
            matches = [
              { "device.nick" = "Fifine K658  Microphone"; }
              { "device.nick" = "JDS Labs EL DAC II+"; }
            ];
            actions = {
              update-props = {
                "device.profile-set" = "analog-only.conf";
              };
            };
          }
        ];
      };
    };
  };
}
