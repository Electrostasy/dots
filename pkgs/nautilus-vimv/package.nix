{
  runCommand
}:

runCommand "nautilus-vimv" { } ''
  DEST="$out/share/nautilus-python/extensions"
  mkdir -p "$DEST"
  ln -s ${./nautilus-vimv.py} "$DEST/nautilus-vimv.py"
''
