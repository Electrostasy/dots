{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "21.11";

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  time.timeZone = "Europe/Vilnius";

  networking = {
    hostName = "jupiter";

    wireless.iwd = {
      enable = true;

      settings = {
        Settings.AutoConnect = true;
        General.EnableNetworkConfiguration = false;
        Network.EnableIPv6 = true;
        Scan.DisablePeriodicScan = true;
      };
    };

    dhcpcd.enable = false;
    useDHCP = false;
    useNetworkd = true;
  };

  systemd.network = {
    enable = true;

    wait-online.timeout = 0;

    networks = {
      "40-wired" = {
        name = "enp0s25";

        DHCP = "yes";
        dns = [ "9.9.9.9" ];
      };

      "40-usb-tethering" = {
        name = "enp0s*u1u*";

        DHCP = "yes";
        dns = [ "9.9.9.9" ];

        networkConfig.IgnoreCarrierLoss = "yes";
      };

      "40-wireless" = {
        name = "wlan*";

        DHCP = "yes";
        dns = [ "9.9.9.9" ];

        networkConfig.IgnoreCarrierLoss = "yes";
        dhcpV4Config = {
          Anonymize = true;
          RouteMetric = 2048;
        };
      };
    };

    links."40-wireless-random-mac" = {
      matchConfig.Type = "wlan*";
      linkConfig.MACAddressPolicy = "random";
    };
  };

  sops = {
    defaultSopsFile = ./secrets.yaml;

    secrets = {
      rootPassword.neededForUsers = true;
      gediminasPassword.neededForUsers = true;
      sshHostKey = { };
    };
  };

  services.openssh.hostKeys = [
    { type = "ed25519"; inherit (config.sops.secrets.sshHostKey) path; }
  ];

  users = {
    mutableUsers = false;

    users = {
      # Change initialHashedPassword using
      # `nix run nixpkgs#mkpasswd -- -m SHA-512 -s`
      root.passwordFile = config.sops.secrets.rootPassword.path;
      gediminas = {
        isNormalUser = true;
        passwordFile = config.sops.secrets.gediminasPassword.path;
        extraGroups = [ "wheel" ];
        uid = 1000;
        shell = pkgs.fish;
      };
    };
  };
}
