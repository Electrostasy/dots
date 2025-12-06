{ pkgs, lib, flake, ... }:

{
  imports = [
    ../../profiles/neovim
    ../../profiles/shell
  ];

  # This somehow conflicts with WSL - if this is enabled and a garbage
  # collection is run, various programs (including bash) cannot be run even
  # though they are present in the store, rendering WSL unbootable:
  # <3>WSL (11 - Relay) ERROR: CreateProcessCommon:725: execvpe(/nix/store/...-wrapped-bash/wrapper) failed: No such file or directory
  system.etc.overlay.enable = false;

  nixpkgs = {
    hostPlatform.system = "x86_64-linux";
    overlays = [
      flake.overlays.libewf-fuse
      flake.overlays.untrunc-anthwlock
    ];
  };

  wsl = {
    enable = true;

    useWindowsDriver = true; # use OpenGL/CUDA from Windows.

    defaultUser = "electro";
  };

  # This somehow conflicts with WSL - if this is enabled, the user specified in
  # wsl.defaultUser is never created:
  # <3>WSL (308 - Relay) ERROR: CreateProcessParseCommon:989: getpwnam(electro) failed 5
  services.userborn.enable = false;

  networking = {
    nameservers = lib.mkForce [ ];
    useDHCP = false;
    useNetworkd = false;
  };

  environment.systemPackages = with pkgs; [
    bintools-unwrapped
    binwalk
    chars
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

  users.allowNoPasswordLogin = true;

  system.stateVersion = "24.11";
}
