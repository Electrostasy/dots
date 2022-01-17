{ config, home-manager, pkgs, ... }:

{
  programs.mpv = {
    enable = true;
    # package = with pkgs; wrapMpv (mpv-unwrapped.override { extraMakeWrapperArgs = [ "--no-window-dragging" ]; });
    bindings = {
      MBTN_LEFT = "ignore";
      MBTN_LEFT_DBL = "ignore";
      "ALT+k" = "add sub-scale +0.1";
      "ALT+j" = "add sub-scale -0.1";
    };
    # https://iamscum.wordpress.com/guides/videoplayback-guide/mpv-conf/
    config = {
      # Force showing subtitles while seeking
      demuxer-mkv-subtitle-preroll = "yes";
      # Load external subtitles with similar name to file
      sub-auto = "fuzzy";
      sub-bold = "yes";
      # Make coloured subtitles gray
      sub-gray = "yes";
      # Overwriting .srt subtitle settings
      sub-font = "Iosevka";
      sub-font-size = 24;
      sub-blur = 0.2;
      sub-border-color = "0.0/0.0/0.0/0.0";
      sub-border-size = 3.0;
      sub-color = "1.0/1.0/1.0/1.0";
      sub-margin-x = 100;
      sub-margin-y = 50;
      sub-shadow-color = "0.0/0.0/0.0/0.25";
      sub-shadow-offset = 0;
      # Load high quality default OpenGL options
      profile = "gpu-hq";
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
      scale = "ewa_lanczossharp";
      dscale = "mitchell";
      cscale = "ewa_lanczossharp";
      # Resample audio instead of dropping frames if video out of sync
      video-sync = "display-resample";
      autofit = "50%";
      # Don't show a volume bar when changing volume
      osd-bar = "no";
      # Audio language priority
      alang = [ "ja" "jp" "jpn" "en" "eng" ];
      # Subtitle language priority
      slang = [ "en" "eng" ];
    };
  };
}
