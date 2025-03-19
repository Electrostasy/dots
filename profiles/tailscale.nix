{ config, ... }:

{
  sops.secrets.tailscaleKey.sopsFile = ../hosts/phobos/secrets.yaml;

  environment = {
    persistence.state.directories = [ "/var/lib/tailscale" ];
    shellAliases.ts = "tailscale";
  };

  services.tailscale = {
    enable = true;

    # Generate new keys on the host running headscale using:
    # $ headscale --user sol preauthkeys create --expiration 99y
    authKeyFile = config.sops.secrets.tailscaleKey.path;

    extraUpFlags = [ "--login-server" "https://controlplane.${config.networking.domain}" ];
  };

  # For some reason, tailscale does not always successfully add the tailnet to
  # /etc/resolv.conf, so hardcode it here.
  services.resolved.domains = [ "sol.tailnet.${config.networking.domain}" ];
}
