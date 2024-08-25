{ modulesPath, ... }:

{
  imports = [ "${modulesPath}/profiles/minimal.nix" ];

  # This breaks fish shell among other things, best to disable it.
  environment.noXlibs = false;
}
