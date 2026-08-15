{ config, pkgs, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/profiles/minimal.nix"
    ../../profiles/common.nix
    ../../profiles/networking.nix
    ../../profiles/shell.nix
    ../../profiles/ssh.nix
    ../../profiles/tailscale.nix
    ../../profiles/users/electro
    ../../profiles/zramswap.nix
    ./klipper.nix
  ];

  nixpkgs.hostPlatform.system = "aarch64-linux";

  image.modules.default.imports = [
    ../../profiles/image/expand-root.nix
    ../../profiles/image/generic-efi.nix
    ../../profiles/image/hybrid-mbr.nix
    ../../profiles/image/platform/raspberrypi-zero-2-w.nix
  ];

  sops.secrets.networkmanager = { };

  hardware.deviceTree = {
    name = "broadcom/bcm2837-rpi-zero-2-w.dtb";

    overlays = [
      # {
      #   name = "disable-bt-overlay";
      #   dtsFile = ./disable-bt.dtso;
      # }
    ];
  };

  boot = {
    loader.systemd-boot.enable = true;

    kernelParams = [ "8250.nr_uarts=1" ];

    initrd = {
      systemd.root = "gpt-auto";
      supportedFilesystems.ext4 = true;
    };
  };

  services.journald = {
    storage = "volatile";

    upload = {
      enable = true;

      settings.Upload.URL = "http://phobos.sol.tailnet.0x6776.lt";
    };
  };

  networking.hostName = "deimos";

  # Required for Wi-Fi.
  hardware.firmware = [ pkgs.raspberrypiWirelessFirmware ];

  networking.networkmanager = {
    enable = true;

    ensureProfiles = {
      environmentFiles = [ config.sops.secrets.networkmanager.path ];

      profiles = {
        home-wifi = {
          connection = {
            id = "home";
            type = "wifi";
            autoconnect = true;
          };

          wifi = {
            ssid = "$SSID_HOME_WIFI";
            mode = "infrastructure";
          };

          wifi-security = {
            key-mgmt = "wpa-psk";
            psk = "$PSK_HOME_WIFI";
          };
        };

        phobos-wifi = {
          connection = {
            id = "home_ap";
            type = "wifi";
            autoconnect = true;
          };

          wifi = {
            ssid = "$SSID_PHOBOS_WIFI";
            mode = "infrastructure";
          };

          wifi-security = {
            key-mgmt = "wpa-psk";
            psk = "$PSK_PHOBOS_WIFI";
          };
        };
      };
    };
  };

  systemd = {
    services.wifi-watchdog = {
      description = "Monitor wireless connectivity state and restore it if lost";
      path = [
        config.networking.networkmanager.package
        pkgs.gnugrep
        pkgs.coreutils-full
      ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "wifi-watchdog.sh" ''
          if [[ $(nmcli -g STATE general status) == 'connected' ]]; then
            exit 0
          fi

          while read -r conn; do
            if [ -z "$conn" ] || [[ $conn == 'lo' ]]; then
              continue
            fi

            if nmcli connection up "$conn"; then
              echo "Connection '$conn' successfully brought up!"
              exit 0
            fi
          done < <(nmcli -g NAME,TYPE connection show | grep 802-11-wireless | cut -d ':' -f 1)

          echo 'Could not bring up any configured connection!' >&2
          exit 1
        '';
      };
    };

    timers.wifi-watchdog = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5m";
        OnUnitActiveSec = "5m";
        Unit = "wifi-watchdog.service";
      };
    };
  };

  system.stateVersion = "25.11";
}
