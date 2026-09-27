# xdg-terminal-exec is missing find, awk, tr ... in its PATH.

final: prev: {
  xdg-terminal-exec = prev.xdg-terminal-exec.overrideAttrs (prevAttrs: {
    buildInputs = prevAttrs.buildInputs ++ [
      prev.coreutils
      prev.findutils
      prev.gawk
    ];

    makeWrapperArgs = [
      "--prefix PATH : ${prev.lib.makeBinPath [
        prev.coreutils
        prev.findutils
        prev.gawk
      ]}"
      "--suffix XDG_DATA_DIRS : '${placeholder "out"}/share'"
    ];

    postFixup = ''
      substituteInPlace $out/bin/xdg-terminal-exec \
        --replace-fail '#!/bin/sh' '#!${prev.lib.getExe prev.dash}'

      wrapProgram "$out/bin/xdg-terminal-exec" ''${makeWrapperArgs[@]}
    '';
  });
}
