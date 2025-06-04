{ config, lib, ... }:

{
  # Perlless profile is too strict and this breaks too many things.
  system.forbiddenDependenciesRegexes = lib.mkForce [];

  # This randomly acts up (especially when network is offline while switching
  # configurations) or breaks on different hardware and I hate it.
  systemd.network.wait-online.enable = lib.mkDefault false;

  # If `extraUpFlags` is changed, then we will require manual intervention with
  # `tailscale up` after activation, repeating all the `extraUpFlags`, and
  # adding `--reset` to the end anyway.
  services.tailscale.extraUpFlags = [ "--reset" ];

  # Building in /tmp can make the tmpfs fill up with build artifacts, which is
  # also meant to be cleaned up on boot:
  # https://github.com/NixOS/nix/issues/11477
  # https://github.com/NixOS/nixpkgs/pull/338181#issuecomment-2349833045
  nix.settings.build-dir = "/var/tmp";

  # Since git 2.35.2 this workaround is needed to fix an annoying error when
  # using `git` or `nixos-rebuild` as non-root in /etc/nixos:
  # fatal: detected dubious ownership in repository at '/etc/nixos'
  programs.git.config.safe.directory = "/etc/nixos";

  # When deploying NixOS configurations with `nixos-rebuild --target-host`, we
  # can get an error about missing valid signatures for store paths built on
  # the build host, the solution is to add the user (or group) on the remote
  # end to trusted-users or sign the store paths with valid signatures:
  # https://github.com/NixOS/nix/issues/2127#issuecomment-1465191608
  nix.settings.trusted-users = [ "@wheel" ];

  # Disable IWD's autoconnect mechanism to have only NetworkManager initiate
  # connections. If left up to IWD, it will never autoconnect to any networks
  # configured through the NetworkManager NixOS option `ensureProfiles`.
  networking.networkmanager.settings = lib.mkIf (config.networking.networkmanager.wifi.backend == "iwd") {
    device."wifi.iwd.autoconnect" = false;
  };

  # Normally, when dconf changes are made to the `user` profile, the user will
  # need to log out and log in again for the changes to be applied. However, in
  # NixOS, this is not sufficient for some cases (automatically enabling
  # extensions), because on a live system, the /etc/dconf path is not updated
  # to the new database on activation. This restores the intended behaviour.
  system.activationScripts.update-dconf-path = lib.mkIf config.programs.dconf.enable {
    text = ''
      dconf_nix_path='${config.environment.etc.dconf.source}'
      if ! [[ /etc/dconf -ef "$dconf_nix_path" ]]; then
        ln -sf "$dconf_nix_path" /etc/dconf
        dconf update /etc/dconf
      fi
    '';
  };
}
