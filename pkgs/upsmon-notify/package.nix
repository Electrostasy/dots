{
  replaceVarsWith,
  nut,
  notify-send-all,
  util-linux,
  wrapperDir ? "/run/wrappers/bin"
}:

replaceVarsWith {
  src = ./upsmon-notify;
  replacements = {
    inherit nut notify-send-all util-linux wrapperDir;
  };
  dir = "bin";
  isExecutable = true;
  meta.mainProgram = "upsmon-notify";
}
