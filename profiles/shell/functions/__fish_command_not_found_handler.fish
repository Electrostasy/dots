function __fish_command_not_found_handler --on-event fish_command_not_found
  # On newly installed systems, we may not have access to a database.
  set -l db_locations '$NIX_INDEX_DATABASE' '$XDG_CACHE_HOME/nix-index/files' '~/.cache/nix-index/files'
  for db_location in $db_locations
    test -e (eval "echo $db_location")
  end

  # If we do not have access to a database, print a helpful error message.
  if test $status -ne 0
    printf 'Packages index not found in search path:\n    %s\n\n' (printf '%s ' $db_locations)
    printf 'Index can be generated using the command:\n    '
    printf 'nix-index --filter-prefix /bin/' | fish_indent --ansi --no-indent

    set -l current_arch (nix eval --impure --raw --expr 'builtins.currentSystem')
    set -l supported_archs "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"
    if contains $current_arch $supported_archs
      set -l uri "https://github.com/nix-community/nix-index-database/releases/latest/download/index-$current_arch"
      set -l text "Community maintained packages index is available"
      printf '\n%s.\n' (hyperlink $uri $text)
    end

    return 1
  end

  # Query the database for packages containing the file.
  set -l packages (command nix-locate --minimal --no-group --type x --type s --top-level --whole-name --at-root /bin/$argv[1] | string replace '.out' '' | sort)

  # Pretty-print the output.
  set -l program (set_color $fish_color_error; printf $argv[1]; set_color $fish_color_normal)
  set -l linked_program (hyperlink "https://search.nixos.org/packages?channel=unstable&query=$argv[1]" $program)
  printf 'The program \'%s\' is not installed.' $linked_program
  if set -q packages[1]
    if test (count $packages) -gt 1
      printf ' It is provided by several packages.\n'
    else
      printf '\n'
    end
    printf 'Spawn a shell containing \'%s\':\n' $program
    printf '    %s\n' (printf 'nix shell nixpkgs#%s\n' $packages | fish_indent --ansi --no-indent)
    printf 'Or run it once with:\n'
    printf '    %s\n' (printf 'nix run nixpkgs#%s\n' $packages | fish_indent --ansi --no-indent)
  else
    printf ' It is not provided by any indexed packages.\n\n' $linked_program
  end
end
