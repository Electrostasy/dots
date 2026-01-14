{
  replaceVars,
  notify-send-all,
  util-linux,
}:

replaceVars ./upsmon-notify.sh {
  inherit notify-send-all util-linux;
}
