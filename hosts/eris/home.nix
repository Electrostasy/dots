{
  home-manager.users.nixos = { pkgs, ... }: {
    imports = [
      ../../profiles/user/neovim
      ../../profiles/user/tealdeer
    ];

    home.stateVersion = "22.11";

    home.packages = with pkgs; [
      bintools-unwrapped
      binwalk
      dos2unix
      evtx # evtx-dump
      exiftool
      ffmpeg
      hashcat
      imagemagick
      john
      libewf
      sleuthkit # mmls, fls, fsstat, icat
      stegseek
      testdisk # photorec
      unixtools.xxd
      xsv
    ];
  };
}
