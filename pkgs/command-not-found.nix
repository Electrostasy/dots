{
  writeShellApplication,
  sqlite,
  path
}:

writeShellApplication {
  name = "command-not-found";

  runtimeInputs = [ sqlite ];

  text = ''
    if [[ ! -e '${path}/programs.sqlite' ]]; then
      echo "Failed to locate package containing '$1': programs.sqlite not found!"
      echo "Please set programs.command-not-found.dbPath in your NixOS configuration to where programs.sqlite is."
      echo "You can disable this feature by setting programs.command-not-found.enable to false in your NixOS configuration."
      return
    fi

    parent_shell="$(ps -o comm= $PPID)"
    mapfile -t packages < <(sqlite3 '${path}/programs.sqlite' "SELECT DISTINCT package FROM Programs WHERE name = '$1';")

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
        # fish_indent removes indentation, so we:
        # 1. save the output to arrays;
        mapfile -t nix_shells < <(fish_indent --ansi <<< "$nix_shells_str")
        mapfile -t nix_runs < <(fish_indent --ansi <<< "$nix_runs_str")
        # 2. remove the trailing newlines;
        unset 'nix_shells[''${#nix_shells[@]}-1]'
        unset 'nix_runs[''${#nix_runs[@]}-1]'
        # 3. re-add the indentation + there is also a broken escape sequence
        # that we need to reset formatting for.
        nix_shells_str="$(printf '  %s\n' "''${nix_shells[@]}")\x1B[1;0m"
        nix_runs_str="$(printf '  %s\n' "''${nix_runs[@]}")\n"
      fi

      output+="You can make it available in an ephemeral shell by typing$maybe_one_of the following:\n$nix_shells_str\n\n"
      output+="You can run it once by typing$maybe_one_of the following:\n$nix_runs_str"
    else
      output+='It is not provided by any indexed packages.'

      if [[ $parent_shell = 'fish' ]]; then
        # We are missing a trailing newline under fish, likely because it calls a
        # bash script.
        output+='\n'
      fi
    fi

    printf '%b' "$output"
  '';
}
