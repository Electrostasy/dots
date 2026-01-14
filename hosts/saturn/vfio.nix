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

    # IOMMU Group 14
    # ├─01:00.0 VGA compatible controller [0300]: NVIDIA Corporation GB206 [GeForce RTX 5060 Ti] [10de:2d04] (rev a1)
    # └─01:00.1 Audio device [0403]: NVIDIA Corporation GB206 High Definition Audio Controller [10de:22eb] (rev a1)
    # IOMMU Group 36
    # └─7b:00.4 USB controller [0c03]: Advanced Micro Devices, Inc. [AMD] Raphael/Granite Ridge USB 3.1 xHCI [1022:15b7]
    # USB controller has 1 port on the rear of the motherboard, to the bottom
    # left of the HDMI port.
    extraModprobeConfig = ''
      softdep nvidia pre: vfio-pci
      softdep xhci_hcd pre: vfio-pci
      options vfio-pci ids=10de:2d04,10de:22eb,1022:15b7

      options kvmfr static_size_mb=128
    '';
  };

  environment.systemPackages = [
    pkgs.looking-glass-client
    pkgs.qemu_kvm
    pkgs.socat
    pkgs.swtpm
    pkgs.virtiofsd

    pkgs.lsiommu
    pkgs.pciutils
    pkgs.usbutils
  ];

  services.udev.packages = [
    # Rules with TAG+="uaccess" need to be set before 73-seat-late.rules
    # (services.udev.extraRules is written to 99-local.rules).
    (pkgs.writeTextFile {
      name = "udev-vfio-rules";
      text = /* udev */ ''
        SUBSYSTEM=="misc", KERNEL=="kvm", TAG+="uaccess"
        SUBSYSTEM=="vfio", TAG+="uaccess"
        SUBSYSTEM=="kvmfr", TAG+="uaccess"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="090c", ATTRS{idProduct}=="1000", TAG+="uaccess"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="064f", ATTRS{idProduct}=="03e9", TAG+="uaccess"
      '';
      destination = "/etc/udev/rules.d/70-vfio.rules";
    })
  ];

  security.pam.loginLimits = [
    # Remove memlock limit to avoid QEMU VFIO DMA errors when run as a
    # non-root user, such as:
    # "<...> failed to setup container for group 14: memory listener initialization failed: Region mem: vfio_container_dma_map <...>"
    { domain = "electro"; type = "-"; item = "memlock"; value = "unlimited"; }

    # Remove open file descriptors limit to avoid virtiofs file descriptor
    # errors when run as a non-root user, such as:
    # "Failure when trying to set the limit to 1000000, the hard limit (524288) of open file descriptors is used instead."
    { domain = "electro"; type = "-"; item = "nofile"; value = "unlimited"; }
  ];
}
