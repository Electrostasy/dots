{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    git
    jq
    parted
    ripgrep
  ];
}
