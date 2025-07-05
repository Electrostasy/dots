{
  writeShellApplication,
  coreutils-full,
  curl,
}:

writeShellApplication {
  name = "is-cached";

  runtimeInputs = [
    coreutils-full
    curl
  ];

  text = builtins.readFile ./is-cached.sh;

  meta.description = "List cache availability for a derivation and its dependencies in https://cache.nixos.org.";
}
