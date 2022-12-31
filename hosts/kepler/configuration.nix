{ config, pkgs, lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./matrix.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  system.stateVersion = "22.05";

  boot = {
    kernel.sysctl."kernel.hostname" = "kepler";

    initrd = {
      availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "xen_blkfront" ];
      kernelModules = [ "nvme" ];
    };
    kernelPackages = pkgs.linuxPackages_latest;
    tmpOnTmpfs = true;

    loader.grub = {
      enable = true;
      version = 2;
      device = "/dev/sda";
    };
  };

  zramSwap = {
    enable = true;
    memoryPercent = 50;
    algorithm = "zstd";
  };

  fileSystems."/" = {
    device = "/dev/sda2";
    fsType = "ext4";
  };

  time.timeZone = "Europe/Vilnius";

  networking = {
    dhcpcd.enable = false;
    useDHCP = false;
    enableIPv6 = false;
    useNetworkd = true;
  };

  services.udev.extraRules = ''
    ATTR{address}=="00:00:59:28:0f:45", NAME="ens3"
  '';

  systemd.network = {
    enable = true;

    wait-online.timeout = 0;

    networks."40-vps" = {
      name = "ens3";

      address = [
        "89.40.15.69/32"
        "10.40.15.69/8"
      ];
      gateway = [ "169.254.0.1" ];
      dns = [
        "109.235.65.143"
        "62.77.159.143"
      ];
      routes = [
        { routeConfig = {
            Scope = "link";
            Destination = "169.254.0.1/32";
            Gateway = "0.0.0.0";
          };
        }
      ];

      networkConfig = {
        IPv6AcceptRA = "no";
        LinkLocalAddressing = "ipv4";
      };
    };
  };

  services.timesyncd.servers = [
    "1.europe.pool.ntp.org"
    "1.lt.pool.ntp.org"
    "2.europe.pool.ntp.org"
  ];

  services.fail2ban.enable = true;

  documentation.enable = false;

  environment.systemPackages = with pkgs; [
    git
    vim
  ];

  sops = {
    defaultSopsFile = ./secrets.yaml;

    secrets = {
      rootPassword.neededForUsers = true;
      sshHostKeyEd25519 = { };
      sshHostKeyRsa = { };
    };
  };

  services.openssh = {
    permitRootLogin = lib.mkForce "prohibit-password";
    hostKeys = [
      { type = "ed25519"; inherit (config.sops.secrets.sshHostKeyEd25519) path; }
      { type = "rsa"; inherit (config.sops.secrets.sshHostKeyRsa) path; }
    ];
  };

  users = {
    mutableUsers = false;

    # Change password in ./secrets.yaml using
    # `nix run nixpkgs#mkpasswd -- -m SHA-512 -s`
    users.root = {
      passwordFile = config.sops.secrets.rootPassword.path;
      openssh.authorizedKeys.keyFiles = [
        ../terra/ssh_electro_ed25519_key.pub
        ../jupiter/ssh_gediminas_ed25519_key.pub
      ];
    };
  };
}
