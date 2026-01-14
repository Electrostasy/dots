{
  replaceVars,
  notify-send-all,
  util-linux,
}:

replaceVars ./mdadm-notify.sh {
  inherit notify-send-all util-linux;
}
