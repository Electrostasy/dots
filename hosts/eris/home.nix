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
    unixtools.xxd
    wget
    xplr
    xsv
  ];
}
