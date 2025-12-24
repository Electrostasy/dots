{
  writeShellApplication,
  pciutils,
  systemd,
  usbutils,
}:

writeShellApplication {
  name = "lsiommu";
  text = builtins.readFile ./lsiommu.sh;
  excludeShellChecks = [ "SC1090" ];
  runtimeInputs = [
    pciutils
    # systemd
    usbutils
  ];
}
