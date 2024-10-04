{ lib, ... }:

{
  # Building in /tmp can make the tmpfs fill up with build artifacts, which is
  # also meant to be cleaned up on boot:
  # https://github.com/NixOS/nix/issues/11477
  # https://github.com/NixOS/nixpkgs/pull/338181#issuecomment-2349833045
  nix.settings.build-dir = "/var/tmp";
  systemd.services.nix-daemon.environment.TMPDIR = "/var/tmp";
  environment.persistence.state.directories = [ "/var/tmp" ];

  # perlless profile is too heavy-handed with this, so we unset it, because
  # some programs like tlp have no perlless alternative.
  system.forbiddenDependenciesRegexes = lib.mkForce [];

  # impermanence conflicts with /etc read-only overlay, making bind mounts fail:
  # https://github.com/nix-community/impermanence/issues/210
  # Seems to break a lot of other things too.
  system.etc.overlay.mutable = true;

  # Since git 2.35.2, rebuilding from repositories owned by non-root users will
  # break `nixos-rebuild`, unless we run `nixos-rebuild` with the `--use-remote-sudo`
  # commandline flag: https://github.com/NixOS/nixpkgs/issues/169193#issuecomment-1103816735
  programs.git.config.safe.directory = "/etc/nixos";

  # When deploying NixOS configurations with `nixos-rebuild --target-host`, we
  # can get an error on missing valid signatures for store paths built on the
  # build host, the solution is to add the user (or group) on the remote end to
  # trusted-users or sign the store paths with valid signatures:
  # https://github.com/NixOS/nix/issues/2127#issuecomment-1465191608
  nix.settings.trusted-users = [ "@wheel" ];

  # With the iwd backend, autoconnect does not work, even if we set
  # `wifi.iwd.autoconnect = false`. If networks are managed with NetworkManager,
  # iwd is not aware of them without converting them to iwd's format, but not
  # using iwd's autoconnect functionality is not working either.
  networking.networkmanager.wifi.backend = "wpa_supplicant";
}
