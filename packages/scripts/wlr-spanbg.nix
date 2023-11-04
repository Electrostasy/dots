{ writeShellApplication
, wlr-randr
, gawk
, swaybg
}:

writeShellApplication {
  name = "wlr-spanbg";
  runtimeInputs = [ wlr-randr gawk swaybg ];
  text = ''
    wlr-randr | awk -v bg="$1" -f ${./wlr-spanbg.awk}
  '';
}
