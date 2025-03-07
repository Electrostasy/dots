{ stdenv
, linuxPackages
, lib
}:

let
  inherit (linuxPackages) kernel kernelModuleMakeFlags;
in

stdenv.mkDerivation (finalAttrs: {
  name = "emc230x-${finalAttrs.version}-${kernel.version}";
  version = "0.1";

  src = ./src;

  nativeBuildInputs = kernel.moduleBuildDependencies;

  makeFlags = kernelModuleMakeFlags ++ [
    "KERNELRELEASE=${kernel.modDirVersion}"
    "KERNEL_DIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
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
