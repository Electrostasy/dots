{ pkgs, lib, ... }:

{
  imports = [
    ../../profiles/neovim
    ../../profiles/shell
  ];

  nixpkgs.hostPlatform.system = "x86_64-linux";

  wsl = {
    enable = true;

    useWindowsDriver = true; # use OpenGL/CUDA from Windows.

    defaultUser = "electro";
  };

  networking = {
    nameservers = lib.mkForce [ ];
    useDHCP = false;
    useNetworkd = false;
  };

  environment.systemPackages = with pkgs; [
    qpdf
    repgrep
    ripgrep-all
    xlsx2csv
  ];

  # This somehow conflicts with WSL - if this is enabled, the user specified in
  # wsl.defaultUser is never created:
  # <3>WSL (308 - Relay) ERROR: CreateProcessParseCommon:989: getpwnam(electro) failed 5
  services.userborn.enable = false;

  # This somehow conflicts with WSL - if this is enabled and a garbage
  # collection is run, various programs (including bash) cannot be run even
  # though they are present in the store, rendering WSL unbootable:
  # <3>WSL (11 - Relay) ERROR: CreateProcessCommon:725: execvpe(/nix/store/...-wrapped-bash/wrapper) failed: No such file or directory
  system.etc.overlay.enable = false;

  users.allowNoPasswordLogin = true;

  system.stateVersion = "24.11";
}
