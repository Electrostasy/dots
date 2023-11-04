{ writeShellApplication
, coreutils
, jq
, udisks
, util-linux
}:

writeShellApplication {
  name = "mountImage";
  runtimeInputs = [
    coreutils # numfmt
    jq
    udisks # udisksctl
    util-linux # sfdisk
  ];
  text = builtins.readFile ./mountImage.sh;
}
