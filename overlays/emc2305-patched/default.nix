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
          # pwm_separate will default to false unless we go the platform data
          # route, so fans will have combined PWM which is a _highly
          # undesirable_ default. This patch makes pwm_separate default to
          # true. Should probably be upstreamed because the mainline driver is
          # unusable for >1 fans without it.
          ./0003-hwmon-emc2305-separate-pwm-fix.patch
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
