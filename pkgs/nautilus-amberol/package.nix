{
  runCommand
}:

runCommand "nautilus-amberol" { } ''
  DEST="$out/share/nautilus-python/extensions"
  mkdir -p "$DEST"
  ln -s ./nautilus-amberol.py "$DEST/"
''
