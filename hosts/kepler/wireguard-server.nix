{ config, pkgs, lib, ... }:

let
  common = import ./wireguard-common.nix { inherit lib; };
  mkPeer = host: {
    wireguardPeerConfig = {
        PresharedKeyFile = config.sops.secrets.wgPresharedKey.path;
        inherit (host) AllowedIPs PublicKey;
      };
    };
in
{
  environment.systemPackages = [ pkgs.wireguard-tools ];

  networking.firewall.allowedUDPPorts = [ common.port ];

  sops = let
    # systemd.netdev(5) manual entry (PrivateKeyFile)
    secretConfig = {
      mode = "0640";
      owner = config.users.users.root.name;
      group = config.users.groups.systemd-network.name;
      sopsFile = ./secrets.yaml;
    };
  in {
    secrets = lib.mapAttrs (_: v: secretConfig // v) {
      wgPresharedKey = { };
      wgPrivateKeyKepler = { };
    };
  };

  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  systemd.network = {
    enable = true;

    networks."20-wg0" = {
      name = "wg0";

      address = common.nodes.kepler.AllowedIPs;
      routes = [
        { routeConfig = {
            Gateway = "10.10.1.1";
            Destination = "10.10.1.0/24";
          };
        }
      ];
    };

    netdevs."wg0" = {
      netdevConfig = {
        Name = "wg0";
        Kind = "wireguard";
        Description = "Wireguard server";
      };

      wireguardConfig = {
        PrivateKeyFile = config.sops.secrets.wgPrivateKeyKepler.path;
        ListenPort = common.port;
      };

      wireguardPeers = with common.nodes; map mkPeer [
        jupiter
        phobos
        terra
        venus
      ];
    };
  };
}
