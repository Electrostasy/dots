{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    cudatoolkit
    cudaPackages.cudnn
  ];

  environment.sessionVariables = {
    LD_LIBRARY_PATH = [
      "/usr/lib/wsl/lib"
      "${pkgs.cudatoolkit}/lib"
      "${pkgs.cudaPackages.cudnn}/lib"
    ];
  };
}
