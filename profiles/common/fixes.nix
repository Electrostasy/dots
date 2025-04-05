{ config, lib, ... }:

{
  system = {
    # Perlless profile sets `system.disableInstallerTools` which removes some
    # common useful utilities.
    tools = {
      nixos-option.enable = lib.mkDefault true;
      nixos-rebuild.enable = lib.mkDefault true;
      nixos-version.enable = lib.mkDefault true;
    };

    # Perlless profile is too strict and this breaks too many things.
    forbiddenDependenciesRegexes = lib.mkForce [];
  };

  nixpkgs.overlays = [
    # Perlless profile re-adds `nixos-rebuild` to `environment.systemPackages`,
    # which is hard to remove. If we use `nixos-rebuild-ng`, `nixos-rebuild`
    # shadows it, so we make `nixos-rebuild-ng` have a higher priority.
    (final: prev: {
      nixos-rebuild-ng = lib.hiPrio prev.nixos-rebuild-ng;
    })
  ];

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

  # Having an immutable /etc is undesirable for at least the following reasons:
  # - impermanence conflicts with /etc read-only overlay, making bind mounts
  # fail: https://github.com/nix-community/impermanence/issues/210
  # - /etc/machine-id is normally populated by systemd, but the immutable /etc
  # prevents that (breaking DHCPv4, journal and other things on systems without
  # a valid machine ID). It can be set to uninitialized in order to force first
  # boot behaviour, systemd normally will then overmount a temporary file which
  # contains the actual machine ID, and after first-boot-complete.target has
  # been reached, the real machine ID would be written to disk), except in our
  # case, the systemd-machine-id-commit.service responsible for it will not run
  # because /etc is still not writable.
  system.etc.overlay.mutable = lib.mkForce true;

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

  # With the iwd backend, autoconnect does not work, even if we set
  # `wifi.iwd.autoconnect = false`. If networks are managed with
  # NetworkManager, iwd is not aware of them without converting them to iwd's
  # format, but not using iwd's autoconnect functionality is not working
  # either. So we force `wpa_supplicant`.
  networking.networkmanager.wifi.backend = "wpa_supplicant";

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
