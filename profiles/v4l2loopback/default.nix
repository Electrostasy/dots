{ config, ... }:

{
  boot = {
    extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];
    kernelModules = [ "v4l2loopback" ];
    extraModprobeConfig = ''
      options v4l2loopback nr_devices=1 exclusive_caps=1 video_nr=0 card_label=v4l2lo0
    '';
  };  
}
