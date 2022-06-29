{ pkgs, ... }:

{
  home.stateVersion = "22.11";

  home.packages = with pkgs; [
    ffmpeg
    hashcat
    imagemagick
    john
    jq
    libewf
    qemu
    ripgrep
    tealdeer
    xplr
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
  };
}
