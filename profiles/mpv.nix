{ pkgs, ... }:

{
  programs.mpv = {
    enable = true;

    scripts = [
      pkgs.mpvScripts.thumbfast
      {
        script = pkgs.mpvScripts.uosc;
        settings = {
          timeline_style = "bar";
        };
      }
    ];

    bindings = {
      # Don't perform window management functions.
      MBTN_LEFT = "ignore";
      MBTN_LEFT_DBL = "ignore";
    };

    settings = {
      osd-bar = "no";
      border = "yes";
      autofit-smaller = "1920x1080";

      demuxer-mkv-subtitle-preroll = "yes"; # force showing subtitles while seeking.
      hr-seek = "yes"; # use precise seeks whenever possible.

      # Load external subtitles with similar name to file.
      sub-auto = "fuzzy";
      sub-bold = "no";
      sub-gray = "yes";

      # Can't selectively override the font for ASS subtitles in libass without
      # stripping all the style tags, so just keep them enabled.
      # sub-ass-override = "yes";
      sub-font = "Recursive Sans Linear Light";
      sub-font-size = 32;
      sub-blur = 0.15;
      sub-border-color = "0.0/0.0/0.0/0.0";
      sub-border-size = 2.0;
      sub-color = "1.0/1.0/1.0/1.0";
      sub-margin-x = 0;
      sub-margin-y = 56;
      sub-shadow-color = "0.0/0.0/0.0/0.85";
      sub-shadow-offset = 0.75;

      vo = "gpu-next";
      hwdec = "vaapi";
      deband = "yes";
      deband-iterations = 4;
      deband-threshold = 35;
      deband-range = 20;
      deband-grain = 5;
      dither-depth = "auto";
      volume = 100;
      volume-max = 100;
      video-sync = "display-resample";

      alang = [ "ja" "jpn" "en" "eng" ];
      slang = [ "en" "eng" ];
    };
  };
}
