{ config, pkgs, lib, ... }:

let
  common = import ./wireguard-common.nix { inherit lib; };
  peer = config.networking.hostName;
  peerCap =
    lib.concatImapStringsSep
      ""
      (i: s: if i == 1 then lib.toUpper s else s)
      (lib.stringToCharacters peer);
in
{
  environment.systemPackages = with pkgs; [
    wireguard-tools
  ];

  sops.secrets = let
    # In systemd.netdev(5) it is specified that secrets accessed by
    # systemd-networkd should have the following permissions (entry
    # for PrivateKeyFile).
    secretConfig = {
      mode = "0640";
      owner = config.users.users.root.name;
      group = config.users.groups.systemd-network.name;
      sopsFile = ./secrets.yaml;
    };
  in lib.mapAttrs (_: v: v // secretConfig) {
    wgPresharedKey = { };
    # This way, only the private key for the current host is decrypted upon
    # activation.
    "wgPrivateKey${peerCap}" = { };
  };

  systemd.network = {
    enable = true;

    networks."20-wg0" = {
      name = "wg0";
      address = common.nodes.${peer}.AllowedIPs;
      routes = [
        { routeConfig = {
            Gateway = "10.10.1.1";
            Destination = "10.10.1.0/24";
            GatewayOnLink = true;
          };
        }
      ];
    };

    netdevs."wg0" = {
      netdevConfig = {
        Name = "wg0";
        Kind = "wireguard";
        Description = "Wireguard peer";
      };

      wireguardConfig = {
        PrivateKeyFile = config.sops.secrets."wgPrivateKey${peerCap}".path;
      };

      wireguardPeers = [
        { wireguardPeerConfig = {
            inherit (common.nodes.kepler) PublicKey;
            Endpoint = "${common.server}:${builtins.toString common.port}";
            PresharedKeyFile = config.sops.secrets.wgPresharedKey.path;
            PersistentKeepalive = 25;
            AllowedIPs = [ "10.10.1.0/24" ];
          };
        }
      ];
    };
  };
}