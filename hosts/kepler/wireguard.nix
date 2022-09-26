{ config, pkgs, lib, ... }:

# Wireguard VPN as a single module to import by the server or peers

# Add new nodes by generating private-public key-pairs:
# $ wg genkey | tee wg-private.key | wg pubkey > wg-public.key

let
  inherit (config.networking) hostName;
  server = "89.40.15.69";
  port = 51820;

  nodes = {
    # Wireguard server
    kepler = {
      AllowedIPs = [ "10.10.1.1/32" ];
      PrivateKeyFile = config.sops.secrets.keplerPrivateKey.path;
      PublicKey = "K9+2GqQVcDHziXuRH0b+0qa/h4hSiHT+Yucvw8nzHiw=";
    };

    # Wireguard peers
    terra = {
      AllowedIPs = [ "10.10.1.2/32" ];
      PrivateKeyFile = config.sops.secrets.terraPrivateKey.path;
      PublicKey = "sD/7po+EE6tudfD161kTNljopV1yRKp4QdMMhvgkcBY=";
    };
    jupiter = {
      AllowedIPs = [ "10.10.1.3/32" ];
      PrivateKeyFile = config.sops.secrets.jupiterPrivateKey.path;
      PublicKey = "+6fRdPzEfxga54TAownHZkB1HWwJnx710sYGsQYo+hI=";
    };
    venus = {
      AllowedIPs = [ "10.10.1.4/32" ];
      PrivateKeyFile = config.sops.secrets.venusPrivateKey.path;
      PublicKey = "aKbnzn8++N5OoTv4tTFKlcq246m1s02s9SUttxoJICo=";
    };
    phobos = {
      AllowedIPs = [ "10.10.1.5/32" ];
      PrivateKeyFile = config.sops.secrets.phobosPrivateKey.path;
      PublicKey = "1oFQGMa4Bqz4fI7eFzv35McKIqM2uHmx84xYUzIoJy8=";
    };
  };

  isServer = hostName == "kepler";
  isPeer = !isServer;
in
{
  environment.systemPackages = [ pkgs.wireguard-tools ];

  networking.firewall.allowedUDPPorts = lib.mkIf isServer [ port ];

  sops = let
    # systemd.netdev(5) manual entry (PrivateKeyFile)
    secretConfig = {
      mode = "0640";
      owner = config.users.users.root.name;
      group = config.users.groups.systemd-network.name;
      sopsFile = ./secrets.yaml;
    };
  in {
    secrets = lib.mapAttrs (_: v: v // secretConfig) {
      presharedKey = { };
      keplerPrivateKey = { };
      terraPrivateKey = { };
      jupiterPrivateKey = { };
      venusPrivateKey = { };
      phobosPrivateKey = { };
    };
  };

  boot.kernel.sysctl."net.ipv4.ip_forward" = lib.mkIf isServer 1;

  systemd.network = {
    enable = true;

    networks."20-wg0" = {
      name = "wg0";

      address = nodes.${hostName}.AllowedIPs;
      routes = [
        { routeConfig = {
            Gateway = "10.10.1.1";
            Destination = "10.10.1.0/24";
            GatewayOnLink = lib.mkIf isPeer true;
          };
        }
      ];
    };

    netdevs."wg0" = {
      netdevConfig = {
        Name = "wg0";
        Kind = "wireguard";
        Description = "Wireguard ${if isServer then "server" else "peer"}";
      };

      wireguardConfig = {
        inherit (nodes.${hostName}) PrivateKeyFile;
        ListenPort = lib.mkIf isServer port;
      };

      wireguardPeers = let
        peers = lib.filterAttrs (n: _: n != "kepler") nodes;
        mkPeer = attrs: {
          wireguardPeerConfig = {
            Endpoint = lib.mkIf isPeer "${server}:${builtins.toString port}";
            PresharedKeyFile = config.sops.secrets.presharedKey.path;
            PersistentKeepalive = lib.mkIf isPeer 25;
            AllowedIPs = if isServer then attrs.AllowedIPs else [ "10.10.1.0/24" ];
            PublicKey = if isServer then attrs.PublicKey else nodes.kepler.PublicKey;
          };
        };
      in
      if isServer then
        builtins.map mkPeer (builtins.attrValues peers)
      else
        lib.singleton (mkPeer peers.${hostName});
    };
  };
}
