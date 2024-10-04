{ pkgs, lib, self, ... }:

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
    useWindowsDriver = true; # use OpenGL/CUDA from Windows.
  };

  # `resolv.conf` is managed by WSL.
  services.resolved.enable = false;
  networking.nameservers = lib.mkForce [ ];

  services.tailscale.enable = false;

  environment.systemPackages = with pkgs; [
    bintools-unwrapped
    binwalk
    dos2unix
    evtx # `evtx-dump`.
    exiftool
    ffmpeg
    hashcat
    imagemagick
    john
    libewf
    mkvtoolnix-cli # `mkvextract`, `mkvinfo`, `mkvmerge`, `mkvpropedit`.
    qpdf
    repgrep
    ripgrep-all
    sleuthkit # `mmls`, `fls`, `fsstat`, `icat`, ...
    stegseek
    testdisk # `fidentify`, `photorec`, `testdisk`.
    unixtools.xxd
    untrunc-anthwlock # `untrunc`.
    xlsx2csv
    xsv
  ];

  system.stateVersion = "22.05";
}
