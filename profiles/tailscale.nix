{ config, ... }:

{
  sops.secrets.tailscaleKey.sopsFile = ../hosts/phobos/secrets.yaml;

  preservation.preserveAt."/persist/state".directories = [ "/var/lib/tailscale" ];

  environment.shellAliases.ts = "tailscale";

  services.tailscale = {
    enable = true;

    # Generate new keys on the host running headscale using:
    # $ headscale --user sol preauthkeys create --expiration 99y
    authKeyFile = config.sops.secrets.tailscaleKey.path;

    extraSetFlags = [
      "--login-server" "https://controlplane.${config.networking.domain}"
    ];
  };

  # For some reason, tailscale does not always successfully add the tailnet to
  # /etc/resolv.conf, so hardcode it here.
  services.resolved.domains = [ "sol.tailnet.${config.networking.domain}" ];

  networking.networkmanager.unmanaged = [ config.services.tailscale.interfaceName ];
  systemd.network.wait-online.ignoredInterfaces = [ config.services.tailscale.interfaceName ];
}
