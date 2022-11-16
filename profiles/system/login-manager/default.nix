{ config, pkgs, lib, ... }:

{
  environment.etc.issue =
    let
      inherit (config.system.nixos) codeName release versionSuffix;
      version = lib.removePrefix "." versionSuffix;
      mkIssue = contents: { source = pkgs.writeText "issue" contents; };
    in
      mkIssue "Welcome to NixOS ${release} (${codeName}) - ${version}\n";

  services.greetd = {
    enable = true;
    settings.default_session.command = ''
      ${pkgs.greetd.tuigreet}/bin/tuigreet \
        --time \
        --asterisks \
        --issue \
        --remember \
        --cmd wayfire
    '';
  };
}
