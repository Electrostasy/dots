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

  # `resolv.conf` is managed by WSL.
  services.resolved.enable = false;
  networking.nameservers = lib.mkForce [ ];

  # DHCP is handled by Windows.
  systemd.network.networks."10-windows-dhcp" = {
    matchConfig.Name = [ "eth*" ];
    networkConfig.DHCP = "no";
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

  system.stateVersion = "24.11";
}
