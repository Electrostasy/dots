{ osConfig, config, pkgs, lib, ... }:

let
  inherit (osConfig.users.users.${config.home.username}) uid;
  runtimeDir = "/run/user/${builtins.toString uid}/";
in

{
  xdg.configFile."mpv/fonts.conf".text = ''
    <?xml version='1.0'?>
    <!DOCTYPE fontconfig SYSTEM 'fonts.dtd'>
    <fontconfig>
      <!-- icon fonts used by uosc osd -->
      <dir>${pkgs.mpvScripts.uosc}/share/mpv/fonts</dir>

      <!-- include user and system fonts that will otherwise be lost -->
      <include prefix="xdg">fontconfig/conf.d</include>
      <include>${osConfig.environment.etc.fonts.source}/conf.d</include>

      <cachedir prefix="xdg">fontconfig</cachedir>
    </fontconfig>
  '';

  # xdg.configFile."mpv/script-opts/thumbfast.conf".text = lib.generators.toKeyValue { } {
  #   socket = runtimeDir + "thumbfast";
  #   thumbnail = runtimeDir + "thumbfast.out";
  #   network = "yes";
  #   hwdec = "yes";
  # };

  xdg.configFile."mpv/script-opts/uosc.conf".text = lib.generators.toKeyValue { } {
    top_bar = "never";
    foreground = "dcd7baff";
    foreground_text = "dcd7ba";
    background = "223249ff";
    background_text = "c8c093";
    chapter_ranges = "openings:25253564,intros:25253564,endings:25253564,outros:25253564";
    timeline_style = "bar";
    timeline_size_min = 2;
    timeline_size_max = 24;
    timeline_size_min_fullscreen = 0;
    timeline_size_max_fullscreen = 24;
    timeline_opacity = 1.0;
    volume = "right";
    volume_size = 24;
    volume_size_fullscreen = 24;
    speed_opacity = 0.0;
  };

  programs.mpv = {
    enable = true;

    scripts = with pkgs.mpvScripts; [
      # Currently broken for some reason, doesn't generate thumbnails, frozen etc.
      # thumbfast
      uosc
    ];

    bindings = {
      MBTN_LEFT = "ignore";
      MBTN_LEFT_DBL = "ignore";
      "ALT+k" = "add sub-scale +0.1";
      "ALT+j" = "add sub-scale -0.1";
    };

    config = {
      # OSC/OSD is replaced with uosc plugin
      osc = "no";
      osd-bar = "no";
      border = "no";
      osd-font = "Recursive Sans Linear Light";

      # PipeWire backend is selected automatically if detected, set it anyway
      ao = "pipewire";

      # Force showing subtitles while seeking
      demuxer-mkv-subtitle-preroll = "yes";

      # Load external subtitles with similar name to file
      sub-auto = "fuzzy";
      sub-bold = "no";
      sub-gray = "yes";

      # Overriding embedded media `ass` subtitles
      sub-ass = "no";
      sub-font = "Recursive Sans Linear Light";
      sub-font-size = 28;
      sub-blur = 0.15;
      sub-border-color = "0.0/0.0/0.0/0.0";
      sub-border-size = 2.0;
      sub-pos = 100;
      sub-color = "1.0/1.0/1.0/1.0";
      sub-margin-x = 0;
      sub-margin-y = 56;
      sub-shadow-color = "0.0/0.0/0.0/0.85";
      sub-shadow-offset = 0.75;

      # Load high quality default OpenGL options
      vo = "gpu";
      profile = "gpu-hq";
      hwdec = "vaapi";
      deband = "yes";
      deband-iterations = 4;
      deband-threshold = 35;
      deband-range = 20;
      deband-grain = 5;
      dither-depth = "auto";
      volume = 100;
      volume-max = 100;
      gpu-context = "wayland";
      # Better video quality
      scale = "ewa_lanczos";
      scale-blur = 0.981251;
      dscale = "mitchell";
      cscale = "ewa_lanczossharp";
      # Resample audio instead of dropping frames if video out of sync
      video-sync = "display-resample";
      autofit = "50%";

      # Audio language priority
      alang = [ "ja" "jp" "jpn" "en" "eng" ];
      # Subtitle language priority
      slang = [ "en" "eng" ];
    };
  };
}
