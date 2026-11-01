{ config, ... }:

{
  networking.firewall.interfaces.${config.services.netbird.clients.default.interface}.allowedTCPPorts = [
    config.services.prometheus.exporters.node.port
  ];

  services.prometheus.exporters.node = {
    enable = true;

    enabledCollectors = [ "cpu.info" ];
  };
}
