{ config, lib, self, ... }:

{
  imports = [ self.inputs.home-manager.nixosModules.default ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    sharedModules = builtins.attrValues self.homeManagerModules ++ [
      # Manual adds a dependency on `nmd`, which breaks `nix flake check`
      # when checking NixOS configurations of other architectures, e.g.
      # running `nix flake check` on x86_64-linux for aarch64-linux.
      { manual.manpages.enable = false; }
    ];
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

  # Makes assertions by Home-Manager easier to read when used as a NixOS
  # module, replacing 'user profile: ...' with 'user@hostname profile: ...'
  # and adding a Nix store path (probably because flakes are imported there).
  # TODO: Add warnings and possibly make these system-wide.
  assertions = lib.mkIf (config.home-manager.users != { }) (with lib; mkOverride 20 (
    flatten (flip
      mapAttrsToList config.home-manager.users (u: c: flip
        builtins.map c.assertions (a: {
          inherit (a) assertion;
          message =
            let
              info = builtins.unsafeGetAttrPos "assertion" a;
              location = "${info.file}:${toString info.line}:${toString info.column}";
            in
              "${u}@${config.networking.hostName} profile${
                if info != null then " in ${location}" else ""
              }: ${a.message}";
        })))));
}
