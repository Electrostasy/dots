{ pkgs, lib, flake, ... }:

{
  imports = [
    ../../profiles/neovim
    ../../profiles/shell
  ];

  nixpkgs = {
    hostPlatform.system = "x86_64-linux";
    overlays = [ flake.overlays.libewf-fuse ];
  };

  wsl = {
    enable = true;

    useWindowsDriver = true; # use OpenGL/CUDA from Windows.
  };

  networking = {
    nameservers = lib.mkForce [ ];
    useDHCP = false;
    useNetworkd = false;
  };

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
  ];

  users.mutableUsers = true; # TODO: Set default user password.

  system.stateVersion = "24.11";
}
