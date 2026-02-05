{
  writeShellApplication,
  coreutils-full,
  pciutils,
  usbutils,
  util-linux,
}:

writeShellApplication {
  name = "lsiommu";
  text = builtins.readFile ./lsiommu.sh;
  runtimeInputs = [
    coreutils-full
    pciutils
    usbutils
    util-linux
  ];
}
