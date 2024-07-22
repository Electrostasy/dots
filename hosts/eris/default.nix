{ pkgs, self, ... }:

{
  imports = [
    ../../profiles/neovim
    ../../profiles/shell
  ];

  system.stateVersion = "22.05";

  nixpkgs = {
    hostPlatform = "x86_64-linux";
    overlays = [ self.overlays.libewf-fuse ];
  };

  wsl = {
    enable = true;
    startMenuLaunchers = false;

    # OpenGL/CUDA from Windows instead.
    useWindowsDriver = true;
  };

  services.tailscale.enable = false;

  environment.systemPackages = with pkgs; [
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
    repgrep
    ripgrep-all
    sleuthkit # mmls, fls, fsstat, icat
    stegseek
    testdisk # photorec
    unixtools.xxd
    xlsx2csv
    xsv
  ];
}
