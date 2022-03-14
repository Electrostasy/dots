{ writeShellApplication, wlr-randr, gawk, swaybg }:

writeShellApplication {
  name = "wlr-spanbg";
  text = ''
    ${wlr-randr}/bin/wlr-randr | ${gawk}/bin/awk -v bg="$1" -f ${./wlr-spanbg.awk}
  '';
  runtimeInputs = [ wlr-randr gawk swaybg ];
}
