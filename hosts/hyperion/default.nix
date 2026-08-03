{ pkgs, modulesPath, flake, ... }:

let
  pkgs' = import flake.inputs.nixpkgs {
    crossSystem = "aarch64-linux";
    localSystem = "x86_64-linux";
  };
in

{
  imports = [
    "${modulesPath}/profiles/minimal.nix"
    ../../profiles/shell.nix
    ../../profiles/ssh.nix
    ../../profiles/tailscale.nix
    ../../profiles/users/electro
    ../../profiles/zramswap.nix
  ];

  nixpkgs.hostPlatform.system = "aarch64-linux";

  image.modules.default.imports = [
    ../../profiles/image/expand-root.nix
    ../../profiles/image/generic-efi.nix
  ];

  hardware.deviceTree = {
    name = "rockchip/rk3576-armsom-sige5.dtb";

    overlays = [
      {
        name = "red-led-on-panic-overlay";
        dtsFile = ./red-led-on-panic.dtso;
      }

      # TODO: Fan control is a bit flaky, sometimes pwm-fan doesn't probe, and
      # when it does probe, it's 100% duty cycle until emul_temp is touched
      # once, then it seems to work fine. Until then, can't control pwm
      # manually in sysfs.
      {
        name = "fan-control-overlay";
        dtsFile = ./fan-control.dtso;
      }
    ];
  };

  boot = {
    loader.systemd-boot.enable = true;

    kernelPackages = pkgs.linuxPackagesFor pkgs'.linuxKernel.kernels.linux_7_1;
    kernelParams = [ "8250.nr_uarts=1" ];

    kernelPatches = map (p: { name = if p ? name then p.name else baseNameOf p; patch = p; }) [
      # [v5,0/6] Add Rockchip RK3576 PWM Support Through MFPWM
      # https://patchwork.kernel.org/cover/14114798
      (pkgs.fetchurl {
        name = "0001-v5-1-6-dt-bindings-pwm-Add-a-new-binding-for-rockchip-rk3576-pwm.diff";
        url = "https://patchwork.kernel.org/patch/14530931/raw";
        hash = "sha256-Hss3b68f92RTBosqqCfEcxqmIhn4TwnRByZP5M4iSIM=";
      })
      (pkgs.fetchurl {
        name = "0002-v5-2-6-mfd-Add-Rockchip-mfpwm-driver.diff";
        url = "https://patchwork.kernel.org/patch/14530932/raw";
        hash = "sha256-sHVMlYPCUvgnuwehv0pV591P+0k65VzWvMPbdwhkcXc=";
      })
      (pkgs.fetchurl {
        name = "0003-v5-3-6-pwm-Add-rockchip-PWMv4-driver.diff";
        url = "https://patchwork.kernel.org/patch/14530933/raw";
        hash = "sha256-KOqyGZd0AzgFcN6IRZ+56Yym/CDNYFgv8lrvQqGqcMQ=";
      })
      (pkgs.fetchurl {
        name = "0004-v5-4-6-counter-Add-rockchip-pwm-capture-driver.diff";
        url = "https://patchwork.kernel.org/patch/14530934/raw";
        hash = "sha256-D12SyRHZNecOk9Zal43VZaazhbTV1obcL5Yo0dBzCps=";
      })
      (pkgs.fetchurl {
        name = "0005-v5-5-6-arm64-dts-rockchip-Add-PWM-nodes-to-RK3576-SoC-dtsi.diff";
        url = "https://patchwork.kernel.org/patch/14530935/raw";
        hash = "sha256-4LIdz314LB7PHZgBXFdgZO+IahLKH7dpex5ky1Smc14=";
      })
    ];

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

  system.stateVersion = "25.05";
}
