final: prev: {
  kernelPackagesExtensions = prev.kernelPackagesExtensions ++ [
    (finalKernelPackages: _:
    let
      inherit (finalKernelPackages) kernel;
    in
    {
      emc2305 = final.stdenv.mkDerivation {
        pname = "emc2305";
        version = "${kernel.version}";

        inherit (kernel) src;

        hardeningDisable = [ "pic" ];
        nativeBuildInputs = kernel.moduleBuildDependencies;

        patches = [
          (final.fetchpatch {
            name = "0001-hwmon-emc2305-Simplify-with-scoped-for-each-OF-child-loop.patch";
            url = "https://patchwork.kernel.org/series/1036367/mbox/";
            hash = "sha256-PdRrNQRBCtaFKjbVzZ+D5ktztV5TIZkl9ovIUtvwI4A=";
          })
          (final.fetchpatch {
            name = "0002-hwmon-emc2305-Support-configurable-fan-PWM-at-shutdown.patch";
            url = "https://patchwork.kernel.org/series/1087257/mbox/";
            hash = "sha256-9xaxnFnZ4nwQ39HlF1oKgGcXq0OQWzgveglDHD2uU8Y=";
          })

          # pwm_separate will always be false on devicetree unless platform
          # data is used, resulting in fans having combined PWM by default.
          # Platform data is not used anywhere, therefore pwm_separate is
          # practically broken according to upstream:
          # https://patchwork.kernel.org/comment/26922589/
          ./0003-hwmon-emc2305-Remove-platform-data.patch
          ./0004-hwmon-emc2305-Remove-pwm_separate.patch
        ];

        postPatch = ''
          cd drivers/hwmon
          cat << 'EOF' > Makefile
obj-m := emc2305.o

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
