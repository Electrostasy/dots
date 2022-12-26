{ config, pkgs, ... }:

{
  home.stateVersion = "22.11";

  xdg.userDirs = {
    enable = true;

    desktop = null; # unused
    documents = "${config.home.homeDirectory}/documents";
    download = "${config.home.homeDirectory}/downloads";
    music = "${config.home.homeDirectory}/music";
    pictures = "${config.home.homeDirectory}/pictures";
    publicShare = null; # unused
    templates = null; # unused
    videos = "${config.home.homeDirectory}/videos";
  };

  fonts.fontconfig.enable = true;

  wayland.windowManager.wayfire.settings.plugins = [
    { plugin = "output:DP-1";
      settings = {
        mode = "3840x2160@119910";
        position = "0,250";
        scale = 1.5;
      };
    }
    { plugin = "output:DP-2";
      settings.mode = "off";
    }
    { plugin = "output:HDMI-A-1";
      settings = {
        mode = "1920x1080@74973";
        position = "2560,0";
        transform = 270;
      };
    }
    { plugin = "autostart";
      settings.wallpapers = "${pkgs.wlr-spanbg}/bin/wlr-spanbg \"$(find ~/pictures -type f | shuf -n1)\"";
    }
  ];

  home.packages = with pkgs; [
    # 3D printing/CAD packages
    cura
    f3d # 3D file viewer (doesn't support *.stl)
    freecad
    fstl # 3D file viewer (specifically for *.stl)
    solvespace
    super-slicer

    # Desktop programs
    element-desktop
    firefox-custom
    gimp
    imv
    keepassxc
    libreoffice
    transmission-qt
    xdg-utils

    # Music
    mpc-cli
    projectm

    # CLI utilities
    chafa
    du-dust
    ffmpeg
    fio
    imagemagick
    pastel
    xplr
    youtube-dl

    # Fonts
    liberation_ttf # Replacement fonts for TNR, Arial and Courier New
    source-han-sans # Required for rendering Japanese font
  ];

  services.mpd = {
    enable = true;

    package = pkgs.mpdWithFeatures {
      features = [
        "audiofile" "dbus" "faad" "ffmpeg" "flac" "icu" "id3tag" "io_uring"
        "libsamplerate" "mad" "mpg123" "opus" "pcre" "alsa" "systemd" "vorbis"
      ];
    };
    musicDirectory = "/mnt/media/music";
    network.startWhenNeeded = true;
  };

  programs = {
    ncmpcpp = {
      enable = true;

      mpdMusicDir = config.services.mpd.musicDirectory;
      settings = {
        mpd_host = "127.0.0.1";
        mpd_port = config.services.mpd.network.port;
        display_bitrate = "yes";
        media_library_primary_tag = "album_artist";
        media_library_albums_split_by_date = "yes";
        progressbar_look = "━━";
        user_interface = "alternative";
        alternative_header_first_line_format = "$6$b$r{ %t }$/b$/r$9";
        alternative_header_second_line_format = "{%a}|{%A} - {%y} - {%b}";
        song_columns_list_format = "(6f)[green]{n} {a} (16)[cyan]{b} (32)[white]{t} (7f)[magenta]{l}";

        selected_item_prefix = "$3$r";
        selected_item_suffix = "$/r$9";
        current_item_prefix = "$6$b$r";
        current_item_suffix = "$/r$/b$9";
      };
      bindings = [
        { key = "p"; command = "pause"; }
        { key = "s"; command = "stop"; }
        { key = "h"; command = "seek_backward"; }
        { key = "l"; command = "seek_forward"; }
        { key = "shift-h"; command = "previous"; }
        { key = "shift-l"; command = "next"; }
        { key = "r"; command = "toggle_repeat"; }
        { key = "shift-r"; command = "toggle_random"; }
        { key = "ctrl-a"; command = "add_item_to_playlist"; }
        { key = "ctrl-d"; command = "delete_playlist_items"; }
        { key = "space"; command = "select_item"; }
        { key = "/"; command = "find_item_forward"; }
        { key = "?"; command = "find_item_backward"; }
        { key = "shift-n"; command = "previous_found_item"; }
        { key = "n"; command = "next_found_item"; }
      ];
    };

    bottom = {
      enable = true;

      settings.flags.tree = true;
    };
  };
}

