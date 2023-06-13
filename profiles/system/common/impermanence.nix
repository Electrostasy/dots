{ config, lib, self, ... }:

{
  imports = [ self.inputs.impermanence.nixosModule ];

  # Guard against tmpfs root issues, namely lack of state management. Does not
  # apply for WSL, as it does not have a NixOS defined root filesystem per the
  # wsl module.
  warnings =
    if
      !config.wsl.enable
      && config.fileSystems."/".device == "none"
      && config.fileSystems."/".fsType == "tmpfs"
      && !config.environment.persistence."/state".enable
    then [ ''
      You have a root on tmpfs configuration without persistence enabled on "/state"
      for host "${config.networking.hostName}".

      This is possibly unintentional, check the option:

        environment.persistence."/state".enable
    '' ] else [];

  # Persist the age private key if sops-nix is used for secrets management.
  # Does not work with impermanence, as it is not mounted early enough in the
  # boot process.
  fileSystems =
    let
      keyFileDir = lib.concatStringsSep "/" (lib.init (lib.splitString "/" config.sops.age.keyFile));
    in
      lib.mkIf (config.sops.secrets != { }) {
        ${keyFileDir} = lib.mkIf (config.environment.persistence."/state".enable) {
          device = "/state" + keyFileDir;
          fsType = "none";
          options = [ "bind" ];
          depends = [ "/state" ];
          neededForBoot = true;
        };
      };

  environment.persistence."/state" = {
    enable = lib.mkDefault false;

    directories = [
      # NixOS configuration directory, used by `nixos-rebuild` etc.
      "/etc/nixos"

      # Kernel, system and other service messages/logs are stored here, which
      # can be useful to keep around between reboots.
      "/var/log"

      # NixOS uses dynamic users for systemd services wherever it can, it is
      # important to persist their UIDs and GIDs to not have corrupted state
      # on disk.
      "/var/lib/nixos"
    ]

    # Directories containing certificates that get signed and renewed.
    # TODO: Migrate to ACME-dependent modules instead.
    ++ lib.optionals
      (config.security.acme.certs != { })
        (builtins.attrValues (
          builtins.mapAttrs (_: v: {
            inherit (v) directory;
            user = "acme";
            group = "acme";
            mode = "u=rwx,g=rx,o=x";
          })
          config.security.acme.certs))

    # PostgreSQL databases.
    # TODO: Migrate to PostgreSQL dependent modules instead.
    ++ lib.optional
      config.services.postgresql.enable
      { directory = config.services.postgresql.dataDir;
        user = config.systemd.services.postgresql.serviceConfig.User;
        group = config.systemd.services.postgresql.serviceConfig.Group;
        mode = "u=rwx,g=rx,o=x";
      }

    # On systems without a RTC (e.g. a Raspberry Pi), the clock file can be
    # crucial for startup, for e.g. DNSSEC keys cannot be validated correctly
    # if the clock is wrong.
    ++ lib.optional
      (config.services.timesyncd.enable || config.services.chrony.enable)
      # /var/lib/systemd/timesync/clock mutates, which can cause issues when
      # it is a bind mount, so we persist its parent directory instead.
      "/var/lib/systemd/timesync";

    files = [
      # This file contains the unique machine ID of the local system,
      # commonly set during installation. Programs may use this ID to identify
      # the host with a globally unique ID in the network.
      "/etc/machine-id"
    ]

    # Contains the device-specific rotated Wireguard private key. If this is
    # not persistent, new devices from the associated Mullvad account have to
    # be removed each time the device is restarted.
    # TODO: Migrate back to Mullvad module.
    ++ lib.optionals
      config.services.mullvad-vpn.enable
      [ "/etc/mullvad-vpn/device.json"
        "/var/cache/mullvad-vpn/relays.json"
      ];
  };
}
