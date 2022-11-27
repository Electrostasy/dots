{ config, pkgs, ... }:

{
  system.stateVersion = "22.05";

  wsl = {
    enable = true;
    defaultUser = "nixos";
    startMenuLaunchers = false;

    wslConf = {
      automount.root = "/mnt";
      network = {
        hostname = config.networking.hostName;
        generateHosts = false;
      };
    };
  };

  networking.hostName = "eris";

  users.users.${config.wsl.defaultUser} = {
    extraGroups = [ "wheel" ];
    uid = 1000;
    shell = pkgs.fish;
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
