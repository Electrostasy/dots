{ config, pkgs, ... }:

# This allows PCI passthrough of my RX 6900 XT to virtual machines
# QEMU configuration and VM not included

{
  boot = {
    # Use the latest kernel
    kernelPackages = pkgs.linuxPackages_latest;
    # Enable IOMMU groups support for Intel CPUs
    kernelParams = [ "intel_iommu=on" "pcie_aspm=off" ];
    # Prevent loading graphics drivers (not necessary in my case)
    # blacklistedKernelModules = [ "amdgpu" "radeon" ];
    # Load extra kernel modules needed for vfio
    kernelModules = [ "kvm-intel" "vfio" "vfio_iommu_type1" "vfio_pci" "vfio_virqfd" ];
    # Attach the GPU to the vfio-pci driver
    # extraModprobeConfig = "options vfio-pci ids=1002:73bf,1002:ab28";
    initrd = {
      availableKernelModules = [ "amdgpu" "vfio-pci" ];
      preDeviceCommands = ''
        DEVS="0000:04:00.0 0000:04:00.1"
        for DEV in $DEVS; do
          echo "vfio-pci" > /sys/bus/pci/devices/$DEV/driver_override
        done
        modprobe -i vfio-pci
      '';
    };
  };

  # Avoid permission errors when passing through evdev USB mouse and keyboard
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="04d9", ATTR{idProduct}=="ad50", GROUP="kvm", MODE="0666"
    SUBSYSTEM=="usb", ATTR{idVendor}=="04d8", ATTR{idProduct}=="eed3", GROUP="kvm", MODE="0666"
  '';

  environment.systemPackages = [ pkgs.virt-manager ];

  users.users.electro.extraGroups = [ "kvm" "libvirtd" ];

  virtualisation.libvirtd = {
    enable = true;
    qemuOvmf = true;
    qemuRunAsRoot = false;
    qemuVerbatimConfig = ''
      cgroup_device_acl = [
        "/dev/input/by-id/usb-04d9_USB_Gaming_Mouse-event-mouse",
        "/dev/input/by-id/usb-Massdrop_Inc._ALT_Keyboard_1559199257-event-kbd",
        "/dev/input/event0",
        "/dev/input/event1",
        "/dev/input/event2",
        "/dev/input/event3",
        "/dev/input/event4",
        "/dev/input/event5",
        "/dev/input/event6",
        "/dev/input/event7",
        "/dev/null",
        "/dev/full",
        "/dev/zero",
        "/dev/random",
        "/dev/urandom",
        "/dev/ptmx",
        "/dev/kvm",
        "/dev/kqemu",
        "/dev/rtc",
        "/dev/hpet"
      ]
      nographics_allow_host_audio = 1
      user = "electro"
      group = "libvirt-qemu"
    '';
    onBoot = "ignore";
    onShutdown = "shutdown";
  };
}
