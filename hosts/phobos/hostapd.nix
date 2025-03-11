{ config, pkgs, ... }:

{
  sops.secrets.hostapd_wlan0 = { };

  # https://github.com/RPi-Distro/firmware-nonfree/issues/34
  # https://github.com/raspberrypi/linux/issues/6049#issuecomment-2595167933
  boot.extraModprobeConfig = ''
    # 0x002000 disables FWSUP/Firmware supplicant.
    # 0x080000 disables SAE/Simultaneous authentication of equals.
    options brcmfmac roamoff=1 feature_disable=0x82000
  '';

  hardware = {
    wirelessRegulatoryDatabase = true;

    firmware = [ pkgs.raspberrypiWirelessFirmware ];
  };

  environment.systemPackages = [ pkgs.iw ];

  systemd.network = {
    netdevs."30-br0".netdevConfig = {
      Name = "br0";
      Kind = "bridge";
      MACAddress = "none"; # inherit MAC so our DHCPv4 IP doesn't change.
    };

    links."30-br0" = {
      matchConfig.OriginalName = "br0";
      linkConfig.MACAddressPolicy = "none";
    };

    networks = {
      "30-br0-ethernet" = {
        matchConfig.Name = "en*";
        networkConfig.Bridge = "br0";
      };

      "30-br0" = {
        matchConfig.Name = "br0";
        linkConfig.RequiredForOnline = "routable";
        DHCP = "yes";
      };
    };
  };

  services.hostapd = {
    enable = true;

    radios.wlan0 = {
      countryCode = "LT";
      channel = 13; # ACS is not working.

      settings.bridge = "br0";

      networks.wlan0 = {
        ssid = "phobos AP";
        authentication = {
          # WPA3/SAE is not supported in upstream Linux yet, maybe downstream:
          # https://github.com/raspberrypi/linux/pull/5945
          mode = "wpa2-sha256";
          wpaPasswordFile = config.sops.secrets.hostapd_wlan0.path;
        };

        # Without this, WPA2 Personal is viewed as Enterprise due to a nixpkgs
        # regression, thus we cannot authenticate:
        # https://github.com/NixOS/nixpkgs/pull/263138
        # https://github.com/raspberrypi/linux/issues/3619
        settings.ieee80211w = 2;
      };
    };
  };
}
