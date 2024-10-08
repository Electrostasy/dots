{ pkgs, lib, self, ... }:

# Currently, WSL with native systemd does not start the systemd user session:
# https://github.com/nix-community/NixOS-WSL/issues/375
# Fix is adapted from https://github.com/microsoft/WSL/issues/8842#issuecomment-2346387618
# into the WSL startup command as a single line (continuations added for readability):
#
# C:\WINDOWS\system32\wsl.exe -d NixOS -u root fish -c \
# "while not test -S /run/dbus/system_bus_socket; \
# sleep 1; \
# end; \
# systemctl restart user@1000; \
# export DBUS_SESSION_BUS_ADDRESS='unix:path=/run/user/1000/bus'; \
# exec sudo --preserve-env=DBUS_SESSION_BUS_ADDRESS --user nixos fish"
#
# This does not seem to work in any shell init code.

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

  system.stateVersion = "24.11";
}
