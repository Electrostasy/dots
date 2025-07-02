{ config, pkgs, ... }:

{
  imports = [
    ../../profiles/minimal.nix
    ../../profiles/shell
    ../../profiles/ssh
    ../../profiles/tailscale.nix
  ];

  nixpkgs.hostPlatform.system = "aarch64-linux";

  image.modules.default.imports = [
    ../../profiles/image/efi.nix
    ../../profiles/image/expand-root.nix
  ];

  sops = {
    defaultSopsFile = ./secrets.yaml;

    secrets = {
      electroPassword.neededForUsers = true;
      electroIdentity = {
        mode = "0400";
        owner = config.users.users.electro.name;
      };
    };
  };

  hardware.deviceTree = {
    name = "rockchip/rk3576-armsom-sige5.dtb";

    overlays = [
      {
        name = "red-led-on-panic-overlay";
        dtsFile = ./red-led-on-panic.dts;
      }
    ];
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = false;
    };

    # TODO: We have neither PWM or hwmon support, I might be missing something
    # but these don't seem to work:
    # https://patchwork.kernel.org/project/linux-rockchip/list/?series=951113
    # https://patchwork.kernel.org/project/linux-rockchip/list/?series=957166
    kernelPackages = pkgs.linuxPackagesFor (pkgs.linuxManualConfig {
      version = "6.14.0-collabora";
      modDirVersion = "6.14.0";

      src = pkgs.fetchFromGitLab {
        domain = "gitlab.collabora.com";
        owner = "hardware-enablement/rockchip-3588";
        repo = "linux";
        rev = "d11b3c9daf21d70b24dfbb4ab69b95540d9eb90d";
        hash = "sha256-Ghw0o/tyDcdq0cDn/pgJUJ6ghD4xh3ysr4CXaPJWUT4=";
      };

      # In order to update/modify the config:
      # $ nix develop /etc/nixos#nixosConfigurations.hyperion.config.boot.kernelPackages.kernel
      # $ unpackPhase
      # $ cd source
      # $ patchPhase
      # $ nix-shell -p 'pkg-config' 'ncurses'
      # $ make menuconfig/oldconfig
      allowImportFromDerivation = true;
      configfile = ./kernel.config;

      extraMeta.branch = "6.14";
    });

    kernelParams = [ "8250.nr_uarts=1" ];

    initrd = {
      includeDefaultModules = false;
      availableKernelModules = [
        "mmc_block" # required to boot from eMMC.
      ];

      systemd = {
        root = "gpt-auto";
        emergencyAccess = true;
        tpm2.enable = false;
      };

      supportedFilesystems.ext4 = true;
    };
  };

  zramSwap.enable = true;

  services.journald.storage = "volatile";

  users.users.electro = {
    isNormalUser = true;
    uid = 1000;

    hashedPasswordFile = config.sops.secrets.electroPassword.path;
    extraGroups = [ "wheel" ];

    openssh.authorizedKeys.keyFiles = [
      ../mercury/id_ed25519.pub
      ../terra/id_ed25519.pub
      ../venus/id_ed25519.pub
    ];
  };

  system.stateVersion = "25.05";
}
