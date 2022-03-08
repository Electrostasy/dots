{ config, pkgs, ... }:

{
  services.greetd = {
    enable = true;
    settings.default_session.command = ''
      ${pkgs.greetd.tuigreet}/bin/tuigreet \
        --time \
        --asterisks \
        --greeting "Access is restricted to authorized users only." \
        --cmd wayfire
    '';
  };
}
