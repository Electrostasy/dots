{ pkgs, self, ... }:

{
  imports = [
    ../../profiles/neovim
    ../../profiles/shell
  ];

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

  services.resolved.enable = false; # resolv.conf is managed by WSL.

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
    qpdf
    repgrep
    ripgrep-all
    sleuthkit # mmls, fls, fsstat, icat
    stegseek
    testdisk # photorec
    unixtools.xxd
    untrunc-anthwlock
    xlsx2csv
    xsv
  ];

  system.stateVersion = "22.05";
}
