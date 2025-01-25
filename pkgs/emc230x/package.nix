{ stdenv
, linux
, lib
}:

# The accepted emc2305 driver submitted by NVIDIA has many issues, and also
# does not make use of many of the features of the chip, such as closed-loop
# RPM fan control. In addition to that, it does not support device tree
# bindings (or per-fan PWM control in my testing) nor creating a kernel cooling
# device.

# This is the emc230x driver submitted by Traverse about a week after NVIDIA's
# driver, which *just works*. It did not get accepted because NVIDIA's was
# accepted first:
# https://patchwork.kernel.org/comment/25009646/

stdenv.mkDerivation (finalAttrs: {
  name = "emc230x-${finalAttrs.version}-${linux.version}";
  version = "0.1";

  src = ./src;

  nativeBuildInputs = linux.moduleBuildDependencies;

  makeFlags = linux.moduleMakeFlags ++ [
    "KERNELRELEASE=${linux.modDirVersion}"
    "KERNEL_DIR=${linux.dev}/lib/modules/${linux.modDirVersion}/build"
  ];

  buildFlags = [ "modules" ];
  installFlags = [ "INSTALL_MOD_PATH=${builtins.placeholder "out"}" ];
  installTargets = [ "modules_install" ];

  meta = {
    description = "Support for the Microchip EMC230x family of RPM-PWM fan controllers";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
  };
})
