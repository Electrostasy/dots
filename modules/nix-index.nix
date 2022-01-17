{ config, lib, ... }:

{
  programs.nix-index = {
    enable = true;
    enableZshIntegration = lib.mkIf config.programs.zsh.enable true;
    enableBashIntegration = lib.mkIf config.programs.bash.enable true;
    enableFishIntegration = lib.mkIf config.programs.fish.enable true;
  };
}
