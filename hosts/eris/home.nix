{ pkgs, ... }:

{
  home.stateVersion = "22.11";

  home.packages = with pkgs; [
    bintools-unwrapped
    binwalk
    dos2unix
    exiftool
    ffmpeg
    file
    hashcat
    imagemagick
    john
    jq
    libewf
    ripgrep
    stegseek
    tealdeer
    unixtools.xxd
    wget
    xplr
    xsv
  ];

  programs.lsd = {
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
}
