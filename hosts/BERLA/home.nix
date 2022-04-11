{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    ffmpeg
    imagemagick
    jq
    ripgrep
    tealdeer
    hashcat
    xplr # TUI scriptable file manager
  ];

  programs = {
    zellij = {
      enable = true;

      settings = {

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

    git = {
      enable = true;
      userName = "Gediminas Valys";
      userEmail = "steamykins@gmail.com";
    };
  };
}
