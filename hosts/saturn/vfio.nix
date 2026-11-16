{ config, pkgs, lib, ... }:

{
  nixpkgs.overlays = [
    (import ../../overlays/looking-glass-client-dev)
  ];

  boot = {
    initrd.kernelModules = [
      "vfio_pci"
      "vfio"
      "vfio_iommu_type1"
    ];

    extraModulePackages = [ config.boot.kernelPackages.kvmfr ];

    kernelModules = [
      "dummy_hcd"
      "kvm-amd"
      "kvmfr"
      "libcomposite"
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
      # Ensure GPU, GPU Audio and USB Controller bind to vfio-pci and not their
      # preferred drivers:
      softdep nvidia pre: vfio-pci
      softdep nouveau pre: vfio-pci
      softdep snd_hda_intel pre: vfio-pci
      softdep xhci_pci pre: vfio-pci

      # Device IDs are as follows:
      # - 10de:2d04 -> NVIDIA GeForce RTX 5060 Ti on 01:00.0
      # - 10de:22eb -> NVIDIA GeForce RTX 5060 Ti Audio Controller on 01:00.1
      # - 1022:15b7 -> xHCI USB 3.1 Controller on 7b:00.4
      options vfio-pci ids=10de:2d04,10de:22eb,1022:15b7

      # 128 MiB IVSHMEM size is required for 3840x2160:
      options kvmfr static_size_mb=128
    '';
  };

  fileSystems."/mnt/machines" = {
    device = "/dev/disk/by-label/machines";
    fsType = "xfs";
    options = [ "noatime" ];
  };

  preservation.preserveAt."/persist/state".users.electro.directories = [
    ".local/state/swtpm/vm-windows-11"
    ".local/state/qemu/vm-windows-11"
  ];

  networking.firewall.interfaces.${config.services.tailscale.interfaceName} = {
    allowedTCPPorts = [ 3389 ];
    allowedUDPPorts = [ 3389 ];
  };

  environment.etc."looking-glass-client.ini".text = /* ini */ ''
    [input]
    rawMouse=yes

    [spice]
    enable=no

    [win]
    disableWaitingMessage=yes
    fullScreen=yes
    noScreensaver=yes
    quickSplash=yes
  '';

  systemd.user.services = {
    "swtpm@" = {
      description = "TPM Emulator for %I";
      restartIfChanged = false;

      serviceConfig = {
        Type = "notify";
        ExecStart = "${lib.getExe pkgs.swtpm} socket --tpm2 --tpmstate dir=%S --ctrl type=unixio,path=%t/%p/%i/swtpm.socket";
        RuntimeDirectory = "%p/%i";
        StateDirectory = "%p/%i";
      };
    };

    "passt@" = {
      description = "Unprivileged networking for %I";
      restartIfChanged = false;

      unitConfig = {
        # passt seems to keep running even when the service that Requires= it
        # is not running anymore unless this is set.
        StopWhenUnneeded = true;
      };

      serviceConfig = {
        Type = "simple";
        ExecStart = "${lib.getExe pkgs.passt} -f --vhost-user --socket-path %t/%p/%i/passt.socket --conf-path %t/%p/%i/passt.control";
        RuntimeDirectory = "%p/%i";
      };
    };

    "virtiofsd@" = {
      description = "Shared file system %f for Virtual Machines";
      restartIfChanged = false;

      serviceConfig = {
        Type = "simple";
        ExecStart = "${lib.getExe pkgs.virtiofsd} --socket-path=%t/%p/%i/virtiofsd.socket --shared-dir='%f' --translate-uid=host:%U:%U:1 --translate-gid=host:%G:%G:1 --writeback";
        RuntimeDirectory = "%p/%i";
        LimitNOFILE = "infinity";
      };
    };

    "looking-glass-client@" = {
      description = "Looking Glass Client for %f";
      restartIfChanged = false;

      serviceConfig = {
        Type = "simple";
        ExecStart = "${lib.getExe pkgs.looking-glass-client} lgmp:shmDevice='%f' win:title='Looking Glass (%f)'";
      };
    };

    "vm-windows-11" = {
      description = "Virtual Machine with Windows 11";
      requires = [
        "swtpm@vm-windows-11.service"
        "passt@vm-windows-11.service"
        "virtiofsd@mnt-pool.service"
      ];
      wants = [
        "looking-glass-client@dev-kvmfr0.service"
      ];
      after = [
        "swtpm@vm-windows-11.service"
        "passt@vm-windows-11.service"
        "virtiofsd@mnt-pool.service"
      ];

      path = [ pkgs.jq ];

      restartIfChanged = false;

      serviceConfig = {
        Type = "simple";
        EnvironmentFile = "/mnt/machines/windows11/qemu.env";
        ExecStartPre = pkgs.writers.writeFish "populate-ovmf.fish" /* fish */ ''
          set -l firmware $STATE_DIRECTORY/OVMF_CODE.fd
          if not test -e $firmware; or not test -r $firmware
            ln -s ${pkgs.OVMFFull.firmware} $firmware
          end

          set -l variables $STATE_DIRECTORY/OVMF_VARS.fd
          if not test -e $variables; or not test -w $variables
            cp ${pkgs.OVMFFull.variables} $variables
            chmod u=rw,go= $variables
          end
        '';
        ExecStart = "${lib.getExe pkgs.qemu_kvm} -name %n $args";
        ExecStartPost = "${lib.getExe' pkgs.passt "pesto"} -t 3389 -u 3389 %t/passt/vm-windows-11/passt.control";
        ExecStop = "${lib.getExe pkgs.socat} UNIX-CONNECT:%t/qemu/%N/qmp.socket EXEC:" + pkgs.writers.writeFish "graceful-shutdown.fish" /* fish */ ''
          function qmpc -a command
            jq -cn --arg command $command '{ execute: $command }'
            read | jq -e 'has("return")' &> /dev/null
          end

          qmpc qmp_capabilities
          qmpc system_powerdown

          while read -l message
            if printf '%s\n' $message | jq -e '.event == "SHUTDOWN"' &> /dev/null
              exit 0
            end
          end
        '';
        TimeoutStopSec = 60;
        Nice = -20;
        RuntimeDirectory = "qemu/%N";
        StateDirectory = "qemu/%N";
        LimitMEMLOCK = "infinity";
      };
    };
  };

  services.udev.packages = [
    (pkgs.writeTextFile {
      name = "udev-vfio-rules";
      text = /* udev */ ''
        # Unprivileged user running QEMU needs access to these devices:
        # - /dev/kvm:
        SUBSYSTEM=="misc", KERNEL=="kvm", TAG+="uaccess"
        # - /dev/vfio*:
        SUBSYSTEM=="vfio", TAG+="uaccess"
        # - /dev/kvmfr*:
        SUBSYSTEM=="kvmfr", TAG+="uaccess"
        # - /dev/bus/usb/*/*:
        SUBSYSTEM=="usb", ATTRS{idVendor}=="0529", ATTRS{idProduct}=="0003", TAG+="uaccess"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="064f", ATTRS{idProduct}=="03e9", TAG+="uaccess"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="090c", ATTRS{idProduct}=="1000", TAG+="uaccess"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="096e", ATTRS{idProduct}=="0006", TAG+="uaccess"
      '';
      # services.udev.extraRules is written to 99-local.rules, but rules with
      # TAG+="uaccess" need to be set before 73-seat-late.rules.
      destination = "/etc/udev/rules.d/70-vfio.rules";
    })
  ];

  # These need to be set for the user session as well as the systemd services.
  security.pam.loginLimits = [
    # Remove memlock limit to avoid QEMU VFIO DMA errors when run as a non-root
    # user. Without this, VFIO devices will not be passed through to the VM.
    # Errors look like the following:
    # "<...> failed to setup container for group 14: memory listener initialization failed: Region mem: vfio_container_dma_map <...>"
    { domain = "electro"; type = "-"; item = "memlock"; value = "unlimited"; }

    # Remove open file descriptors limit to avoid virtiofs file descriptor
    # errors when sharing directories with many files and running as a non-root
    # user. Errors look like the following:
    # "Failure when trying to set the limit to 1000000, the hard limit (524288) of open file descriptors is used instead."
    { domain = "electro"; type = "-"; item = "nofile"; value = "unlimited"; }
  ];
}
