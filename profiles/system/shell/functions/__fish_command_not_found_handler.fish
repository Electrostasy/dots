function __fish_command_not_found_handler --on-event fish_command_not_found
  set -l query $argv[1]
  set -l attrs (command nix-locate --minimal --no-group --type x --type s --top-level --whole-name --at-root "/bin/$query")
  set attrs (string replace '.out' '' $attrs | string collect | sort)

  echo -n "The program '"
  set_color $fish_color_error; echo -n "$query"

  if string trim $attrs | string length --quiet
    set_color $fish_color_normal; echo -n "' is not installed."
  else
    set_color $fish_color_normal; echo "' could not be located."
    return 127
  end

  if [ (count $attrs) -gt 1 ]
    echo " It is provided by several packages."
  else
    echo ""
  end
  echo -n "Spawn a shell containing '"
  set_color $fish_color_error; echo -n "$query"
  set_color $fish_color_normal; echo "':"

  for attr in $attrs
    echo -n "  $(echo "nix shell nixpkgs#$attr" | fish_indent --ansi --no-indent)"
  end
  echo -e "\nOr run it once with:"
  for attr in $attrs
    echo -n "  $(echo "nix run nixpkgs#$attr" | fish_indent --ansi --no-indent)"
  end

  set_color $fish_color_normal
end
