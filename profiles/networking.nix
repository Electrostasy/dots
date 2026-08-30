{ config, lib, ... }:

{
  networking = {
    nameservers = [
      "9.9.9.9"
      "1.1.1.1"
    ];

    timeServers = [
      "1.europe.pool.ntp.org"
      "1.lt.pool.ntp.org"
      "2.europe.pool.ntp.org"
    ];

    firewall.enable = true;
    nftables.enable = true;

    # This defaults to true because of `networking.networkmanager`.
    # Use 999 for a higher priority than the default 1000.
    modemmanager.enable = lib.mkOverride 999 false;

    networkmanager = {
      wifi.backend = lib.mkDefault "iwd";

      settings = {
        # Disable IWD's autoconnect mechanism to have only NetworkManager
        # initiate connections. If left up to IWD, it will never autoconnect to
        # any networks configured through the option
        # `networking.networkmanager.ensureProfiles`.
        device."wifi.iwd.autoconnect" = lib.mkIf (config.networking.networkmanager.wifi.backend == "iwd") false;
      };
    };

    # Use the systemd-networkd networking backend and translate `networking.*`
    # options to it.
    useNetworkd = lib.mkDefault true;

    # Default to DHCP for all interfaces independent of networking backend.
    useDHCP = lib.mkDefault true;
  };

  systemd.network = {
    # Only one can be enabled, otherwise we will run into errors saying we have
    # no network.
    wait-online.enable = !(config.networking.networkmanager.enable && config.systemd.services.NetworkManager-wait-online.enable);

    networks."99-wireless-client-dhcp" = {
      # Follow RFC 7844 (Anonymity Profiles for DHCP Clients) for Wi-Fi
      # interfaces to minimize disclosure of identifying information.
      dhcpV4Config = {
        Anonymize = true;
      };
    };

    links."99-wireless-client-random-mac" = {
      matchConfig = {
        WLANInterfaceType = "station";
      };

      linkConfig = {
        # Required by Anonymize=true, have the kernel use a random MAC address
        # for Wi-Fi interfaces each time the device appears.
        MACAddressPolicy = "random";
      };
    };
  };
}
