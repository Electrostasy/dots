{
  writeShellApplication,
  sqlite,
  procps,

  path,
  dbPath ? path
}:

writeShellApplication {
  name = "command-not-found";

  runtimeInputs = [
    sqlite
    procps
  ];

  text = ''
    if [[ ! -e '${dbPath}' ]]; then
      echo '${dbPath} is missing!'
      echo 'Please set programs.command-not-found.dbPath in your NixOS configuration to where programs.sqlite is.'
      echo 'You can disable this feature by setting programs.command-not-found.enable to false in your NixOS configuration.'
      return 127
    fi

    parent_shell="$(ps -o comm= $PPID)"
    mapfile -t packages < <(sqlite3 '${dbPath}' "SELECT DISTINCT package FROM Programs WHERE name = '$1';")

    # shellcheck disable=SC1003 # false positive.
    output="The program '$(printf '\e]8;;%s\e\\\%s\e]8;;\e\\' "https://search.nixos.org/packages?channel=unstable&query=$1" "$1")' is not in your PATH. "

    if [[ ''${#packages[@]} -ge 1 ]]; then
      maybe_one_of=
      if [[ ''${#packages[@]} -eq 1 ]]; then
        output+='It is provided by one package.\n'
      else
        output+='It is provided by several packages.\n'
        maybe_one_of=' one of'
      fi

      nix_shells_str="$(printf '  nix shell nixpkgs#%s\n' "''${packages[@]}")"
      nix_runs_str="$(printf '  nix run nixpkgs#%s\n' "''${packages[@]}")"

      # If this script is called from a fish shell, colour the suggested commands.
      if [[ $parent_shell = 'fish' ]] && command -v fish_indent &> /dev/null; then
        nix_shells_str="$(fish_indent --ansi --only-unindent <<< "$nix_shells_str")"
        nix_runs_str="$(fish_indent --ansi --only-unindent <<< "$nix_runs_str")"
      fi

      output+="You can make it available in an ephemeral shell by typing$maybe_one_of the following:\n$nix_shells_str\n\n"
      output+="You can run it once by typing$maybe_one_of the following:\n$nix_runs_str"
    else
      output+='It is not provided by any indexed packages.'
    fi

    if [[ $parent_shell = 'fish' ]]; then
      # We are missing a trailing newline under fish, likely because it calls a
      # bash script.
      output+='\n'
    fi

    printf '%b' "$output"
  '';
}
