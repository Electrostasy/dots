{ config, pkgs, ... }:

{
  boot = {
    initrd.kernelModules = [
      "vfio_pci"
      "vfio"
      "vfio_iommu_type1"
    ];

    extraModulePackages = [ config.boot.kernelPackages.kvmfr ];

    kernelModules = [
      "kvm-amd"
      "kvmfr"
    ];

    blacklistedKernelModules = [
      "nouveau"
      "nvidia"
      "nvidia-drm"
      "nvidia-modeset"
      "nvidia-uvm"
      "nvidiafb"
    ];

    extraModprobeConfig = ''
      # Bind the NVIDIA VGA and audio devices.
      softdep drm pre: vfio-pci
      options vfio-pci ids=10de:2d04,10de:22eb

      options kvmfr static_size_mb=128
    '';
  };

  # systemd.network = {
  #   netdevs."30-macvtap0" = {
  #     netdevConfig = {
  #       Name = "macvtap0";
  #       Kind = "macvtap";
  #     };
  #
  #     extraConfig = ''
  #       [MACVTAP]
  #       Mode=bridge
  #     '';
  #   };
  #
  #   networks."30-macvtap-interface" = {
  #     matchConfig.Name = "enp3s0f[01]";
  #     networkConfig.MACVTAP = "macvtap0";
  #   };
  # };

  environment.systemPackages = [
    pkgs.looking-glass-client
    pkgs.qemu_kvm
    pkgs.swtpm
    # Because of:
    # https://gitlab.com/virtio-fs/virtiofsd/-/issues/96#note_2510783294
    # https://github.com/rust-vmm/vm-memory/issues/195#issuecomment-2754783866
    # we need:
    # https://gitlab.com/virtio-fs/virtiofsd/-/merge_requests/306
    # for:
    # https://github.com/rust-vmm/vm-memory/pull/320
    # But we can't override virtiofsd because overriding cargoHash is currently broken:
    # https://discourse.nixos.org/t/overriding-version-cant-find-new-cargohash/31502/7
    # https://discourse.nixos.org/t/is-it-possible-to-override-cargosha256-in-buildrustpackage/4393/27
    # https://github.com/NixOS/nixpkgs/pull/435239
    # pkgs.virtiofsd

    pkgs.lsiommu
    pkgs.pciutils
    pkgs.usbutils
  ];

  services.udev.extraRules = /* udev */ ''
    SUBSYSTEM=="vfio", GROUP="kvm", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="kvmfr", GROUP="kvm", MODE="0660", TAG+="uaccess"
    SUBSYSTEM=="usb", GROUP="kvm", MODE="0660", TAG+="uaccess"
  '';

  users.users.electro.extraGroups = [ "kvm" ];

  security.pam.loginLimits = [
    { domain = "electro"; type = "-"; item = "memlock"; value = "unlimited"; }
  ];
}
