{ config, pkgs, lib, ... }:

{
  xdg.enable = true;

  home.packages = with pkgs; [
    alsaUtils
    bottom # System resources monitor
    chafa # Image data terminal previewer
    cura # 3D printer slicer software
    du-dust # Disk usage visualizer
    eww-wayland # Desktop widgets
    f3d # 3D file format viewer
    ffmpeg
    firefox-custom
    gimp
    grim # Wayland compositor image grabber
    imagemagick
    inter # UI typeface
    iosevka-nerdfonts
    keepassxc # Password manager
    liberation_ttf # Replacement fonts for TNR, Arial and Courier New
    (libreoffice.overrideAttrs (_: { langs = [ "en-US" "lt" ]; }))
    neofetch
    pastel # Generate, analyze, convert and manipulate colours
    quintom-cursor-theme
    # rink # Unit-aware calculator/conversion tool
    ripgrep
    schildichat-desktop-wayland # Matrix chat client
    slurp # Wayland compositor region selector
    solvespace # Parametric 3D CAD
    source-han-sans # Japanese OpenType/CFF fonts
    super-slicer # 3D printer slicer software
    # swayidle # Idle management daemon
    # swaylock # Screen locker
    tealdeer # `tldr` alternative
    # (texlive.combine { inherit (texlive) scheme-minimal lithuanian hyphen-lithuanian collection-langenglish; })
    transmission-qt # BitTorrent client
    wf-recorder # Record wayland displays
    wl-clipboard # `wl-{copy,paste}` clipboard utilities
    xdg-utils # for xdg-open
    xplr # TUI scriptable file manager
    xwayland
  ];

  fonts.fontconfig.enable = true;

  programs = {
    zathura.enable = true;

    rofi = {
      enable = true;

      package = pkgs.rofi-wayland;
      plugins = [ ];
      terminal = "${pkgs.kitty}/bin/kitty";
      extraConfig = {
        modi = "drun,run";
        kb-primary-paste = "Control+V";
        kb-secondary-paste = "Control+v";
      };
    };

    lsd = {
      enable = true;

      settings = {
        classic = false;
        blocks = [ "permission" "user" "group" "size" "date" "name" ];
        date = "+%Y-%m-%d %H:%M:%S %z";
        dereference = true;
        sorting = {
          column = "name";
          dir-grouping = "first";
        };
      };
    };

    fish.functions = {
      reboot-windows = {
        description = "Reboot into Windows if it is present";
        body = ''
          set -l windows (${pkgs.efibootmgr}/bin/efibootmgr | grep 'Windows Boot Manager')
          if [ "$status" -eq 1 ]
            echo 'Cannot reboot into Windows: Windows not found'
          else
            for text in "Rebooting into Windows in 3..." "2..." "1..."
              echo -n "$text" && sleep 1
            end
            set -l next_boot (echo "$windows" | cut -d '*' -f1 | cut -c 5-)
            if sudo ${pkgs.efibootmgr}/bin/efibootmgr -n "$next_boot"
              reboot
            end
          end
        '';
      };
      share-screen = {
        description = "Share a selected screen using v4l2";
        body = ''
          set -l intro 'Select a display to begin sharing to /dev/video0.\nOnce selected, "mpv --demuxer-lavf-format=video4linux2 av://v4l2:/dev/video0" to preview.'
          set -l command "echo $intro; wf-recorder --muxer=v4l2 --file=/dev/video0 -c rawvideo -o (slurp -o -f \"%o\") -x yuyv422"

          kitty fish -c "$command"
        '';
      };
    };

    git = {
      enable = true;
      userName = "Gediminas Valys";
      userEmail = "steamykins@gmail.com";
    };
  };
}

