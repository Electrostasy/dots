{ stdenv
, linux
, lib
}:

# The hwmon emc2305 driver present in Linux 6.1 and later, originally submitted
# by NVIDIA, does not have device tree support nor closed-loop RPM fan control.
# This makes it rather crippled. The kernel maintainers are unwilling to accept
# any fan controller drivers with DT bindings until someone creates a
# "standard" fan controller DT binding. The upstream driver also has many other
# issues which the Raspberry Pi people have been trying to fix in their
# downstream kernel fork.

# This is the hwmon emc230x driver submitted by Traverse about a week after
# NVIDIA's driver, which *just works*. It did not get accepted because NVIDIA's
# was accepted first:
# https://patchwork.kernel.org/comment/25009646/
# https://gitlab.traverse.com.au/ls1088firmware/traverse-sensors/-/tree/78802abc95f625316283e9dce39354621daa745a#microchip-emc230x-family-fan-controllers

# The Traverse driver originally did not feature PWM fan control nor device
# tree based probing, which I have added in this version of the driver for
# personal use.

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
