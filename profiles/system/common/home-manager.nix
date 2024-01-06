{ config, lib, self, ... }:

{
  imports = [ self.inputs.home-manager.nixosModules.default ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
  };

  # NixOS is unaware of home-manager variables because home-manager does not
  # manage the shell, so its session variables must be sourced in NixOS. This
  # takes priority over NixOS variables.
  environment.extraInit = lib.optionalString (config.home-manager.users != { }) /* bash */ ''
    HM_SESSION_VARS="/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh"
    if test -e "$HM_SESSION_VARS"; then
      . "$HM_SESSION_VARS"
    fi
  '';
}
