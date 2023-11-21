{ config, pkgs, ... }:

{
  imports = [
    ../../profiles/system/common
    ../../profiles/system/shell
    ./home.nix
  ];

  system.stateVersion = "22.05";

  nixpkgs.hostPlatform = "x86_64-linux";

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