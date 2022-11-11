{ config, pkgs, lib, ... }:

# Ensure that all internet traffic (domain name lookups) are not routed through
# the ISP:
# https://www.dnsleaktest.com/

{
  networking = {
    nameservers = [ "127.0.0.1" "::1" ];
    dhcpcd.extraConfig = lib.mkIf config.networking.dhcpcd.enable "nohook resolv.conf";
    networkmanager.dns = lib.mkIf config.networking.networkmanager.enable "none";
    resolvconf.enable = lib.mkDefault false;
  };

  services.dnscrypt-proxy2 = {
    enable = true;
    settings = {
      require_dnssec = true;
      require_nolog = true;
      require_nofilter = true;
      force_tcp = false;
      block_ipv6 = true;
      timeout = 5000;
      sources.public-resolvers = {
        urls = [
          "https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md"
          "https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md"
        ];
        cache_file = "/var/lib/dnscrypt-proxy2/public-resolvers.md";
        # Update PK from `https://github.com/DNSCrypt/dnscrypt-resolvers`
        minisign_key = "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3";
      };
      blocked_names.blocked_names_file = "${pkgs.stevenblack-blocklist}/hosts";
    };
  };
}

