{ config, pkgs, ... }:

{
  imports = [ ./container.nix ];

  hardware.opengl.driSupport32Bit = true;
}
