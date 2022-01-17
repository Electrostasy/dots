{ writeShellScriptBin, wlr-randr, gawk }:

writeShellScriptBin "wlr-spanbg" ''
  ${wlr-randr}/bin/wlr-randr | ${gawk}/bin/awk -v bg=$1 -f ${./wlr-spanbg.awk}
''
