{ config, modulesPath, ... }:

{
  imports = [
    "${modulesPath}/profiles/minimal.nix"
    ../../profiles/common.nix
    ../../profiles/networking.nix
    ../../profiles/shell.nix
    ../../profiles/ssh.nix
    ../../profiles/tailscale.nix
    ../../profiles/telemetry.nix
    ../../profiles/users/electro
    ../../profiles/zramswap.nix
    ./fail2ban.nix
    ./fileserver.nix
    ./headscale.nix
    ./hostapd.nix
    ./murmur.nix
    ./prometheus.nix
    ./prosody.nix
  ];

  nixpkgs.hostPlatform.system = "aarch64-linux";

  image.modules.default.imports = [
    ../../profiles/image/expand-root.nix
    ../../profiles/image/generic-efi.nix
    ../../profiles/image/platform/raspberrypi-4-b.nix
  ];

  hardware.deviceTree.name = "broadcom/bcm2711-rpi-4-b.dtb";

  boot = {
    loader.systemd-boot.enable = true;

    kernelParams = [ "8250.nr_uarts=1" ];

    initrd = {
      systemd.root = "gpt-auto";
      supportedFilesystems.ext4 = true;

      # /persist is mounted from a USB connected SATA SSD, which cannot be
      # found without these kernel modules.
      availableKernelModules = [
        "pcie_brcmstb" # required for the PCIe bus.
        "reset-raspberrypi" # required for the VL805 USB controller.
      ];
    };
  };

  fileSystems."/persist" = {
    device = "/dev/disk/by-label/pidata";
    fsType = "btrfs";
    options = [
      "subvol=persist"
      "noatime"
    ];
    neededForBoot = true;
  };

  preservation = {
    enable = true;

    preserveAt."/persist/state".directories = [
      "/var/log/journal"
      "/var/log/nginx"
      "/var/lib/acme"
    ];
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "steamykins@gmail.com";
  };

  services = {
    nginx = {
      enable = true;

      recommendedTlsSettings = true;

      virtualHosts."0x6776.lt" = {
        # Enable https://letsencrypt.org/docs/challenge-types/#http-01-challenge.
        enableACME = true;

        # Create an HTTPS server block in addition to HTTP.
        addSSL = true;
      };
    };

    journald.remote.enable = true;
  };

  networking = {
    hostName = "phobos";

    firewall = {
      enable = true;

      allowedTCPPorts = [
        80
        443
      ];

      interfaces.${config.services.tailscale.interfaceName}.allowedTCPPorts = [
        config.services.journald.remote.port
      ];
    };
  };

  system.stateVersion = "25.05";
}
