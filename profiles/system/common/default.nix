{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    file
    git
    jq
    nix-prefetch
    parted
    ripgrep
    unzip
    zip
  ];
}
