{ pkgs, ... }:

{
  programs.mpv = {
    enable = true;

    scripts = [
      pkgs.mpvScripts.thumbfast
      {
        script = pkgs.mpvScripts.uosc;
        settings = {
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
      cursor-autohide = "always";

      demuxer-mkv-subtitle-preroll = "yes"; # force showing subtitles while seeking.
      hr-seek = "yes"; # use precise seeks whenever possible.

      # Load external subtitles with similar name to file.
      sub-auto = "fuzzy";
      sub-bold = "no";
      sub-gray = "yes";

      # Can't selectively override the font for ASS subtitles in libass, without
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

      # Language priority
      alang = [ "ja" "jpn" "en" "eng" ];
      slang = [ "en" "eng" ];
    };

    fonts = /* xml */ ''
      <?xml version='1.0'?>
      <!DOCTYPE fontconfig SYSTEM 'fonts.dtd'>
      <fontconfig>
        <!-- Icon fonts used by `uosc` script. -->
        <dir>${pkgs.mpvScripts.uosc}/share/mpv/fonts</dir>
        <include ignore_missing="yes">/etc/fonts/conf.d</include>
        <include ignore_missing="yes">/etc/fonts/local.d</include>
      </fontconfig>
    '';
  };
}
