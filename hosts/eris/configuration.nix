{ config, pkgs, ... }:

{
  system.stateVersion = "22.05";

  wsl = {
    enable = true;
    automountPath = "/mnt";
    defaultUser = "nixos";
    startMenuLaunchers = false;

    wslConf = {
      network = {
        hostname = config.networking.hostName;
        generateHosts = false;
      };
    };
  };

  networking.hostName = "eris";

  users.users.${config.wsl.defaultUser} = {
    shell = pkgs.fish;
    extraGroups = [ "wheel" ];
  };

  # CUDA support
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    cudatoolkit
    cudaPackages.cudnn
  ];
  environment.sessionVariables.LD_LIBRARY_PATH = [
    "/usr/lib/wsl/lib"
    "${pkgs.cudatoolkit}/lib"
    "${pkgs.cudaPackages.cudnn}/lib"
  ];
}
