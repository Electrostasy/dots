{ config, pkgs, ... }:

{
  services.teamviewer.enable = true;
  nixpkgs.allowedUnfreePackages = with pkgs; [ teamviewer ];
  systemd.services.teamviewerd.serviceConfig = {
    # https://gist.github.com/ageis/f5595e59b1cddb1513d1b425a323db04
    NoNewPrivileges = "yes";
    PrivateDevices = "yes";
    PrivateMounts = "yes";
    PrivateTmp = "yes";
    PrivateUsers = "yes";
    ProtectControlGroups = "yes";
    ProtectHome = "yes";
    ProtectKernelModules = "yes";
    ProtectKernelTunables = "yes";
    ProtectSystem = "full";
  };
}
