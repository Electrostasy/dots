{
  writeShellApplication,
  jq,
}:

writeShellApplication {
  name = "diff-closures";

  runtimeInputs = [ jq ];

  text = ''
    if [[ $# -eq 0 ]]; then
      set -- "/run/current-system" "/etc/nixos#nixosConfigurations.\"$HOSTNAME\".config.system.build.toplevel"
    elif ! nix path-info --derivation "$1" "$2" &> /dev/null; then
      echo 'Error: arguments must evaluate to Nix derivations!'
      exit 1
    fi

    ${./diff-closures.jq} \
      <(nix derivation show --recursive "$1") \
      <(nix derivation show --recursive "$2") \
      <(nix derivation show /run/current-system/sw/bin/*)
  '';

  meta.description = "Show what packages and versions changed between two closures without building them.";
}
