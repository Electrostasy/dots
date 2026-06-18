{ config, ... }:

{
  networking.firewall.interfaces.${config.services.tailscale.interfaceName}.allowedTCPPorts = [ config.services.prometheus.exporters.node.port ];

  services.prometheus.exporters.node = {
    enable = true;

    enabledCollectors = [ "cpu.info" ];
  };
}
