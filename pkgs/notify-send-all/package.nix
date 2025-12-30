{
  writeShellApplication,
  coreutils-full,
  libnotify,
}:

writeShellApplication {
  name = "notify-send-all";
  text = builtins.readFile ./notify-send-all.sh;

  runtimeInputs = [
    coreutils-full
    libnotify
  ];
}
