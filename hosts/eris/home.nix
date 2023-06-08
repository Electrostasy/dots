{
  home-manager.users.nixos = { pkgs, ... }: {
    imports = [
      ../../profiles/user/fish
      ../../profiles/user/lsd
      ../../profiles/user/neovim
      ../../profiles/user/tealdeer
    ];

    home.stateVersion = "22.11";

    home.packages = with pkgs; [
      bgrep
      bintools-unwrapped
      binwalk
      dos2unix
      evtx # evtx-dump
      exiftool
      ffmpeg
      file
      hashcat
      imagemagick
      john
      jq
      libewf
      ripgrep
      sleuthkit # mmls, fls, fsstat, icat
      stegseek
      testdisk # photorec
      unixtools.xxd
      wget
      xplr
      xsv
    ];
  };
}
