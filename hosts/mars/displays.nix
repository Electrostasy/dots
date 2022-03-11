{ pkgs, ... }:

{
  services.kanshi = {
    enable = true;
    systemdTarget = "graphical-session.target";
    profiles.normal = {
      exec = "${pkgs.wlr-spanbg}/bin/wlr-spanbg \"$(find ~/Pictures -type f | shuf -n1)\"";
      outputs = [
        {
          # Acer XV273K
          criteria = "DP-2";
          status = "enable";
          mode = "3840x2160@119.910Hz";
          position = "0,1080";
          scale = 1.5;
        }
        {
          # BenQ Xl2420T
          criteria = "DP-1";
          status = "enable";
          mode = "1920x1080@119.982Hz";
          position = "360,0";
        }
        {
          # Random LG
          criteria = "HDMI-A-1";
          status = "enable";
          mode = "1920x1080@74.973Hz";
          position = "2560,860";
          transform = "270";
        }
      ];
    };
    profiles.notop = {
      exec = "${pkgs.wlr-spanbg}/bin/wlr-spanbg \"$(find ~/Pictures -type f | shuf -n1)\"";
      outputs = [
        {
          # Acer XV273K
          criteria = "DP-2";
          status = "enable";
          mode = "3840x2160@119.910Hz";
          position = "0,1080";
          scale = 1.5;
        }
        {
          # Random LG
          criteria = "HDMI-A-1";
          status = "enable";
          mode = "1920x1080@74.973Hz";
          position = "2560,860";
          transform = "270";
        }
      ];
    };
  };
}
