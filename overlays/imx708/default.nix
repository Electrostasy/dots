# Currently, only raw bayer data capture is possible because there is no driver
# for the ISP.
# To capture raw data:
# $ v4l2-ctl -d /dev/video0 --set-fmt-video=width=4608,height=2592,pixelformat=RG10 --stream-mmap --stream-count=1 --stream-to=frame.bin
# This gives us 10-bit values and shows up as near black, they need to be scaled down manually:
#
# import numpy as np
# from PIL import Image
#
# with open('frame.bin', 'rb') as f:
#     data = np.frombuffer(f.read(), dtype=np.uint16)
#
# # Reshape to image.
# img = data.reshape(2592, 4608)
#
# # Scale 10-bit (0-1023) → 8-bit (0-255) for display.
# img_8bit = (img.astype(np.float32) / 1023 * 255).astype(np.uint8)
#
# Image.fromarray(img_8bit, mode='L').save('frame_scaled.png')
# print(f"Saved frame_scaled.png")
#
# In order to debayer in hardware, we need to build the bcm2835-isp driver.

final: prev: {
  kernelPackagesExtensions = prev.kernelPackagesExtensions ++ [
    (finalKernelPackages: _:
    let
      inherit (finalKernelPackages) kernel;
      inherit (prev) fetchpatch;
    in
    {
      # TODO: This driver is required to use the ISP's fixed function hardware
      # to debayer in hardware, providing YUYV.
      # TODO: I'm not sure I can even build all these as a module?
      # bcm2835-isp = prev.stdenv.mkDerivation {
      #   pname = "bcm2835-isp";
      #   version = "${kernel.version}";
      #
      #   inherit (kernel) src;
      #
      #   hardeningDisable = [ "pic" ];
      #   nativeBuildInputs = kernel.moduleBuildDependencies;
      #
      #   patches = [
      #     # https://patchwork.kernel.org/cover/14094495
      #     (fetchpatch {
      #       name = "0001-platform-raspberrypi-Add-Broadcom-Videocore-shared-memory-support.patch";
      #       url = "https://patchwork.kernel.org/series/1038382/mbox/";
      #       hash = "";
      #     })
      #     # https://patchwork.kernel.org/cover/14101153
      #     (fetchpatch {
      #       name = "0002-media-Add-support-for-Broadcom-RPi-BCM2835-ISP.patch";
      #       url = "https://patchwork.kernel.org/series/1052591/mbox/";
      #       hash = "";
      #     })
      #   ];
      # };

      dw9807-vcm = prev.stdenv.mkDerivation {
        pname = "dw9807-vcm";
        version = "${kernel.version}";

        inherit (kernel) src;

        hardeningDisable = [ "pic" ];
        nativeBuildInputs = kernel.moduleBuildDependencies;

        patches = [
          # Patches taken from the rpi-6.18.y branch.
          (fetchpatch {
            name = "0001-media-dw9807-vcm-Add-support-for-DW9817-bidirectional-VCM-driver.patch";
            url = "https://github.com/raspberrypi/linux/commit/8e84b3a0a18c88cb399ade64d65710867d815cfc.patch";
            hash = "sha256-czIn2pT+aTW57PiTduJ9Ul0Z7Wu+aPJH8QxODXRwtCA=";
          })
          (fetchpatch {
            name = "0002-media-dt-bindings-Add-regulator-to-dw9807-vcm.patch";
            url = "https://github.com/raspberrypi/linux/commit/c6ff51571bd94b0202a30c1b4791172e28604879.patch";
            hash = "sha256-aiQUNabGOmCOrWOPb1uIm+jwRiJpQSHiVkIDm/5/V+A=";
          })
          (fetchpatch {
            name = "0003-media-dw9807-vcm-Add-regulator-support-to-the-driver.patch";
            url = "https://github.com/raspberrypi/linux/commit/2dbd8f2b2bdea951afe00970589b82035f4fd2bd.patch";
            hash = "sha256-Rl7O3pZ19IPXSSdA3hR1MN7HqL0tijyRYlxsxEK9ECY=";
          })
          (fetchpatch {
            name = "0004-media-dw9807-vcm-Smooth-the-first-user-movement-of-the-lens.patch";
            url = "https://github.com/raspberrypi/linux/commit/4126e8b2c2e4919d9c300ac3e89503e7ea552fb4.patch";
            hash = "sha256-i7ZjdzP7st/iuME/ZpjgmkplrRhcWDGPACqdpWHf/dM=";
          })
        ];

        postPatch = ''
          cd drivers/media/i2c
          cat << 'EOF' > Makefile
obj-m := dw9807-vcm.o

modules:
	$(MAKE) -C "$(KERNEL_DIR)" M="$(PWD)" modules

modules_install:
	$(MAKE) -C "$(KERNEL_DIR)" M="$(PWD)" modules_install
EOF
        '';

        makeFlags = [ "KERNEL_DIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build" ];
        installFlags = [ "INSTALL_MOD_PATH=${placeholder "out"}" ];

        buildTargets = [ "modules" ];
        installTargets = [ "modules_install" ];
      };

      imx708 = prev.stdenv.mkDerivation {
        pname = "imx708";
        version = kernel.version;

        inherit (kernel) src;

        hardeningDisable = [ "pic" ];
        nativeBuildInputs = kernel.moduleBuildDependencies;

        patches = [
          # Patches taken from the rpi-6.7.y branch.
          (fetchpatch {
            # Submitted driver is https://patchwork.kernel.org/cover/13114298,
            # but it needs to be adapted to accept downstream patches anyway so
            # might as well use the downstream driver to start with. This way a
            # ~1300 line patch does not need to be vendored for adapting it to
            # the downstream driver.
            name = "0001-media-i2c-Add-a-driver-for-the-Sony-IMX708-image-sensor.patch";
            url = "https://github.com/raspberrypi/linux/commit/d1c690eb87abe1144508f237ee908ea793d45eec.patch";
            hash = "sha256-bOelCLroahRaHP+jpQNKCIi7zzUlaw2nDVk7LsPSluU=";
            excludes = [
              # These produce conflicts and are not necessary for building as a
              # module in our case.
              "drivers/media/i2c/Kconfig"
              "drivers/media/i2c/Makefile"
            ];
          })
          (fetchpatch {
            name = "0002-drivers-media-imx708-Enable-long-exposure-mode.patch";
            url = "https://github.com/raspberrypi/linux/commit/9604353017eb17cbb0ed38e1cde09ec090959fbb.patch";
            hash = "sha256-Ol+moerIEisMJN0ZqjLgEaZ3wkFNI+An8ZBMO9Gbjdg=";
          })
          (fetchpatch {
            name = "0003-drivers-media-i2c-imx708-Fix-crop-information.patch";
            url = "https://github.com/raspberrypi/linux/commit/11646c3447ce5d62c2ae9f1edb6ee10c65bc2bb3.patch";
            hash = "sha256-e9NG8c4I6EZWqahSO1cOZj3S+p8pXc1U/VVaFfaNAYE=";
          })
          (fetchpatch {
            name = "0004-drivers-media-i2c-imx708-Fix-WIDE_DYNAMIC_RANGE-control-with-long-exposure.patch";
            url = "https://github.com/raspberrypi/linux/commit/b4c2c97937d413b095ad749065f9c79950161102.patch";
            hash = "sha256-g4rG/4aBtjjZ7jD6s2UmoeGD/1v0Bo93reEaLpsGWJ0=";
          })
          (fetchpatch {
            name = "0005-drivers-media-imx708-Increase-usable-link-frequencies.patch";
            url = "https://github.com/raspberrypi/linux/commit/a601dff419b3dd894e1c541eb8a31c663b0c2a4c.patch";
            hash = "sha256-85Rgz78xYa1xWnV1EqG4SUX1PJHg7Rd27BkonzisEUg=";
          })
          (fetchpatch {
            name = "0006-drivers-media-imx708-Remove-unused-control-fields.patch";
            url = "https://github.com/raspberrypi/linux/commit/a8da98c50d1146f4bbd15996147bc5068cbe533e.patch";
            hash = "sha256-PBS/WwEBEwPW+o/f0nt37zIsOwAZvzdEkjq6kSvOvsc=";
          })
          (fetchpatch {
            name = "0007-drivers-media-imx708-Tidy-ups-to-address-upstream-review-comments.patch";
            url = "https://github.com/raspberrypi/linux/commit/82312220b90089d3f20a3035c118395ed302f04f.patch";
            hash = "sha256-kTja/gtjK7NMfLFhzyB4STTuXFKh73mZ1Cl/3EA4lJE=";
          })
          (fetchpatch {
            name = "0008-drivers-media-imx708-Follow-the-standard-devicetree-labels.patch";
            url = "https://github.com/raspberrypi/linux/commit/34892d38cf92e37d910785e01b8b0ac489704c10.patch";
            hash = "sha256-Nqj3uygabIQ5efkgPjj9Wnmvww8fPHsaYDaGdYnjrb0=";
          })
          (fetchpatch {
            name = "0009-drivers-media-imx708-Put-HFLIP-and-VFLIP-controls-in-a-cluster.patch";
            url = "https://github.com/raspberrypi/linux/commit/eb0d4f887c9c1753f11e285b3c3c27988dc61694.patch";
            hash = "sha256-agPCscR+/OUSiMk9Z/u2j5G6+M1cmcllSoiqVGOoppY=";
          })
          (fetchpatch {
            name = "0010-drivers-media-imx708-Adjust-broken-line-correction-parameter.patch";
            url = "https://github.com/raspberrypi/linux/commit/68e22a2bfc509ef64f694617da6dbee3ab875674.patch";
            hash = "sha256-3kG8p+WEly4Kh6WgDlPjLjutp0xC7irvfpfIHkF8ZJs=";
          })

          # In downstream's rpi-6.8.y branch, the commit history up to this
          # point seems to have been squashed, this patch replicates the
          # changes introduced in the squash.
          ./0011-media-i2c-imx708-Squash-fixes.patch

          # Patches taken from the rpi-6.12.y branch (some missing since
          # rpi-6.13.y, squashed in rpi-6.18.y, then missing again up to and
          # including rpi-7.1.y...).
          (fetchpatch {
            name = "0012-media-i2c-imx708-Fix-lockdep-issues.patch";
            url = "https://github.com/raspberrypi/linux/commit/96f6b239ff694192416df9cc3f8e130fb7b19301.patch";
            hash = "sha256-KHQnpwukO7WU5CZptu9gcoqrV8j/Yh/K13sEj7QxrII=";
          })
          (fetchpatch {
            name = "0013-media-i2c-Tweak-default-PDAF-gain-table-in-imx708-driver.patch";
            url = "https://github.com/raspberrypi/linux/commit/686f5708baaafb35e03e6e56396339330d0fec48.patch";
            hash = "sha256-6W8cCJMDRUBaVGynojWCkbCXKAvmkUHWRi29XWESMWk=";
          })
          (fetchpatch {
            name = "0014-drivers-i2c-imx708-Use-pm_runtime_use_autosuspend.patch";
            url = "https://github.com/raspberrypi/linux/commit/6b7a0deb1c500741973928195ef63ac128edb232.patch";
            hash = "sha256-QFmvK+MpN79sfdyKdJGFxIWz7kvJjVukGc8UJ9/iUr8=";
          })

          # Patches taken from the rpi-6.18.y branch (missing in rpi-6.19.y).
          (fetchpatch {
            name = "0015-media-imx708-Support-configuring-continuous-clock-from-DT.patch";
            url = "https://github.com/raspberrypi/linux/commit/9c30fcd000f66a5e49f89b8086cbbc22f72d9d98.patch";
            hash = "sha256-o7fJtLHEpOWBPatFHRfm5CfFGN7HAPjZb98X3820C/A=";
          })

          # Downstream has a pending PR for adding streams and CSI2 embedded
          # metadata support proper, including for the imx708 driver:
          # https://github.com/raspberrypi/linux/pull/6437
          # Streams and embedded data in mainline are under development:
          # https://patchwork.kernel.org/cover/14125193
          # https://patchwork.kernel.org/cover/14113268
          # Once they are merged upstream, it is likely the imx708 driver will
          # be submitted for review once more. Trying to add these patch series
          # is unfeasible right now, some patches are missing or something (a
          # new version is probably being prepared).

          ./0016-drivers-media-imx708-Adapt-to-upstream.patch
        ];

        postPatch = ''
        cd drivers/media/i2c
        cat << 'EOF' > Makefile
obj-m := imx708.o

modules:
	$(MAKE) -C "$(KERNEL_DIR)" M="$(PWD)" modules

modules_install:
	$(MAKE) -C "$(KERNEL_DIR)" M="$(PWD)" modules_install
EOF
        '';

        makeFlags = [ "KERNEL_DIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build" ];
        installFlags = [ "INSTALL_MOD_PATH=${placeholder "out"}" ];

        buildTargets = [ "modules" ];
        installTargets = [ "modules_install" ];
      };
    })
  ];
}
