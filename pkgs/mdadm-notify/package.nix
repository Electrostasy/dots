{
  replaceVarsWith,
  notify-send-all,
  util-linux,
}:

replaceVarsWith {
  src = ./mdadm-notify;
  replacements = {
    inherit notify-send-all util-linux;
  };
  dir = "bin";
  isExecutable = true;
  meta.mainProgram = "mdadm-notify";
}
